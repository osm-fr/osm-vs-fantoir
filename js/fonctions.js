/*--------------- FEEDBACK ---------------*/
    
    let hoveredStateId = null;
    let context_menu = null;
    DELTA = 0.0008;
    VERSION_MENU = 2;
    NB_SUGGESTIONS_MAX = 20;

    function is_valid_dept(d){
        pattern_dept = new RegExp('^([01]|[3-8])([0-9])$|^2([aAbB]|[1-9])$|^9([0-5]|7[1-6]|87|88)$')
        res = false
        if (pattern_dept.test(d)){
            res = d
        }
        return res
    }
    function get_dept_from_insee(code_insee){
        if (code_insee.substr(0,2) == '97'||code_insee.substr(0,2) == '98'){
            return code_insee.substr(0,3)
        }
        return code_insee.substr(0,2)
    }
    function check_url_for_dept(){
        var res
        if (window.location.hash != ""){
            if (window.location.hash.split('dept=')[1]){
                if (window.location.hash.split('dept=')[1].split('&')[0]){
                    if (is_valid_dept(window.location.hash.split('dept=')[1].split('&')[0])){
                        res = window.location.hash.split('dept=')[1].split('&')[0]
                    }
                }
            }
        }
        if (window.location.search && res==undefined){
            if (window.location.search.split('dept=')[1]){
                if (window.location.search.split('dept=')[1].split('&')[0]){
                    if (is_valid_dept(window.location.search.split('dept=')[1].split('&')[0])){
                        res = window.location.search.split('dept=')[1].split('&')[0]
                    }
                }
            }
        }
        if ((window.location.hash.split('dept=')[1] || window.location.search.split('dept=')[1]) && res == undefined){
            alert("Aucun numéro de département valide trouvé dans l'URL\n\nAbandon")
        }
        return res
    }
    function check_url_for_offset(){
        var res = 0
        if (window.location.search){
            if (window.location.search.split('offset=')[1]){
                if (window.location.search.split('offset=')[1].split('&')[0]){
                    if (Number.isInteger(Number.parseInt(window.location.search.split('offset=')[1].split('&')[0]))){
                        res = window.location.search.split('offset=')[1].split('&')[0]
                    }
                }
            }
        }
        return res
    }
    function check_form_for_dept(){
        res = false
        if (is_valid_dept($('#input_dept')[0].value)){
            res = $('#input_dept')[0].value
        } else {
            alert($('#input_dept')[0].value+' n\'est pas un numero de département valide\n\nAbandon')
        }
        return res
    }
    function check_url_for_ratio_map(){
        if (window.location.search){
            if (window.location.search.includes('ratio=')){
                ratio = window.location.search.split('ratio=')[1].split('&')[0]
                return ratio
            }
        }
        return 0
    }
    function check_url_for_fantoir(){
        var res
        pattern_fantoir = new RegExp('^[0-9][0-9abAB][0-9]{3}[0-9|a-z|A-Z]{4}$')
        sp = new URLSearchParams(window.location.search)
        if (sp.get('fantoir')){
            if (pattern_fantoir.test(sp.get('fantoir'))){
                return sp.get('fantoir')
            }
            return (sp.get('fantoir')+ 'n\'est pas un code FANTOIR valide\n\nAbandon')
        }
        return res
    }
    function check_url_for_xyz(){
        if (window.location.hash){
            if (window.location.hash.includes('map=')){
                let [z,x,y] = window.location.hash.split('map=')[1].split('&')[0].split('/')
                if (!Number.isNaN(z) && !Number.isNaN(x) && !Number.isNaN(y)){
                    return [z,x,y]
                }
            }
        }
        return [-1,9999,9999]
    }
    function check_url_for_insee(){
        pattern_insee = new RegExp('^[0-9][0-9abAB][0-9]{3}$')
        var res
        if (window.location.hash){
            if (window.location.hash.includes('insee=')){
                if (window.location.hash.split('insee=')[1].split('&')[0]){
                    if (pattern_insee.test(window.location.hash.split('insee=')[1].split('&')[0])){
                        res = window.location.hash.split('insee=')[1].split('&')[0]
                    } else {
                        alert(window.location.hash.split('insee=')[1].split('&')[0]+' n\'est pas un code INSEE de commune\n\nAbandon')
                    }
                }
            }
        }
        if (window.location.search && res == undefined){
            if (window.location.search.includes('insee=')){
                if (window.location.search.split('insee=')[1].split('&')[0]){
                    if (pattern_insee.test(window.location.search.split('insee=')[1].split('&')[0])){
                        res = window.location.search.split('insee=')[1].split('&')[0]
                    } else {
                        alert(window.location.search.split('insee=')[1].split('&')[0]+' n\'est pas un code INSEE de commune\n\nAbandon')
                    }
                }
            }
        }
        return res
    }
    function add_map_link(table,href,text){
        $('#'+table+' tr:last').append($('<td>')
                                    .append($('<a>')
                                    .attr('href',href)
                                    .attr('target','blank')
                                    .text(text)))
    }
    function add_id_link(table,href,text){
        $('#'+table+' tr:last')     .append($('<td title="iD">').addClass('zone-clic-id')
                                        .append($('<a>').attr('href',href).attr('target',"blank")
                                            /*.text(text)*/
                                        )
                                        .on('mouseup', function(){
                                            if(event.which==1 || event.which==2) {
                                                $(this).addClass('clicked');
                                            }
                                        })
                                    )
    }
    function add_josm_link(table,xl,xr,yb,yt,code_insee,nom_commune){
        $('#'+table+' tr:last').append($('<td title="JOSM">').addClass('zone-clic-josm')
                                    .attr('xleft',xl).attr('xright',xr).attr('ybottom',yb).attr('ytop',yt)
                                    /*.text('JOSM')*/
                                    .click(function(){
                                        if (!device_is_mobile()){check_josm_remote_control()}
                                        srcLoadAndZoom = 'http://127.0.0.1:8111/load_and_zoom?left='+xl+'&right='+xr+'&top='+yt+'&bottom='+yb+'&changeset_tags='+get_changeset_tags_noms(code_insee,nom_commune);
                                        $('<img>').appendTo($('#josm_target')).attr('src',srcLoadAndZoom);
                                        $(this).addClass('clicked');
                                    })
                                )
    }
    function add_josm_croisement_link(table,xl,xr,yb,yt,commune1,insee1,commune2,insee2,wayid){
        $('#'+table+' tr:last').append($('<td title="JOSM">').addClass('zone-clic-josm')
                                    .attr('xleft',xl).attr('xright',xr).attr('ybottom',yb).attr('ytop',yt)
                                    /*.text('JOSM')*/
                                    .click(function(){
                                        if (!device_is_mobile()){check_josm_remote_control()}
                                        srcLoadAndZoom = 'http://127.0.0.1:8111/load_and_zoom?left='+xl+'&right='+xr+'&top='+yt+'&bottom='+yb+'&select=way'+wayid+'&changeset_tags='+get_changeset_tags_croisement((xl+xr)/2,(yb+yt)/2,commune1,insee1,commune2,insee2);
                                        $('<img>').appendTo($('#josm_target')).attr('src',srcLoadAndZoom);
                                        $(this).addClass('clicked');
                                    })
                                )
    }
    function add_josm_addr_link(table,code_insee,nom_commune,fantoir,nom_fantoir,nombre,fantoir_dans_relation,is_place,schema_point_uniquement){
        d = new Date()
        moisjour = d.getMonth()+''+d.getDate()
        if (moisjour == '31'){
            classeZonePoint = 'zone-points'
            classeZoneRelation = 'zone-relation'
            titlePoint = nombre+' Point(s)'
            titleRelation = 'Relation'
            textNbPoints = ''
            text1Point = '1'
            textRelation = ''
            textLD = ''
        } else {
            classeZonePoint = ''
            classeZoneRelation = ''
            titlePoint = ''
            titleRelation = ''
            textNbPoints = ' Points'
            text1Point = '1 Point'
            textRelation = 'Relation'
            textLD = ' (lieu-dit)'
        }
        stringToRemove = window.location.href.split('?')[0].split('/').pop()
        $('#'+table+' tr:last').append($('<td>').addClass('zone-clic-adresses').addClass(classeZonePoint).attr('title',titlePoint))
        $('#'+table+' tr:last td:last').append($('<span>').text(nombre > 1 ? nombre+textNbPoints:text1Point))
                                            .click(function(){
                                                if (!device_is_mobile()){check_josm_remote_control()}
                                                srcURL = 'http://127.0.0.1:8111/import?changeset_tags='+get_changeset_tags_addr(code_insee,nom_commune)+'&new_layer=true&layer_name='+nom_fantoir+'&url='+window.location.href.split('?')[0].replace(stringToRemove,'')+'requete_numeros.py?insee='+code_insee+'&fantoir='+fantoir+'&modele='+((is_place) ? 'Place':'Points')+'&filaire='+localStorage.PreferencesAddrRueAvecPoints;
                                                $('<img>').appendTo($('#josm_target')).attr('src',srcURL);
                                                $(this).addClass('clicked');
                                            })
        if (is_place){
            $('#'+table+' tr:last td:last').attr('colspan','2').append($('<span>').text(textLD))
        } else if (schema_point_uniquement||!eval(localStorage.PreferencesAddrRelation)){
            $('#'+table+' tr:last td:last').attr('colspan','2')
        } else {
            $('#'+table+' tr:last').append($('<td>').addClass('zone-clic-adresses').addClass(classeZoneRelation).attr('title',titleRelation).append($('<span>'))
                                        .text(textRelation)
                                        .click(function(){
                                            if (!device_is_mobile()){check_josm_remote_control()}
                                            localStorage.setItem('PreferencesAddrRelation','true')
                                            srcURL = 'http://127.0.0.1:8111/import?changeset_tags='+get_changeset_tags_addr(code_insee,nom_commune)+'&new_layer=true&layer_name='+nom_fantoir+'&url='+window.location.href.split('?')[0].replace(stringToRemove,'')+'requete_numeros.py?insee='+code_insee+'&fantoir='+fantoir+'&modele=Relation&fantoir_dans_relation='+fantoir_dans_relation;
                                            $('<img>').appendTo($('#josm_target')).attr('src',srcURL);
                                            $(this).addClass('clicked');
                                        })
                                    )
        }
    }
    function add_addr_inspector_link(table,code_insee,fantoir,source){
        $('#'+table+' tr:last').append($('<td>').addClass('zone-clic-adresses')
                                        .append($('<a>').attr('href',"numeros.html?insee="+code_insee+'&fantoir='+fantoir+'&source='+source+'&tab=0').attr('target',"blank")
                                        .text('Qualifier')
                                        )
                                        .on('mouseup', function(){
                                            if(event.which==1 || event.which==2) {
                                                $(this).addClass('clicked');
                                            }
                                        })
                                        )
    };
    function get_changeset_tags_addr(code_insee,nom_commune){
        return "source=https://bano.openstreetmap.fr/pifometre/index.html?insee="+code_insee+"%7Chashtags=%23BANO %23Pifometre%7Ccomment=Intégration d'adresses - "+nom_commune+" ("+code_insee+")"
    }
    function get_changeset_tags_noms(code_insee,nom_commune){
        return "source=https://bano.openstreetmap.fr/pifometre/index.html?insee="+code_insee+"%7Chashtags=%23BANO %23Pifometre%7Ccomment=Intégration de noms de voies et lieux-dits - "+nom_commune+" ("+code_insee+")"
    }
    function get_changeset_tags_croisement(x,y,commune1,insee1,commune2,insee2){
        if (commune2 != undefined && insee2 != undefined){
            comment = "Correction des rues et routes à cheval entre "+commune1+" ("+insee1+" ) et "+commune2+" ("+insee2+")"
        } else {
            comment = "Correction des rues et routes à cheval vers "+commune1+" ("+insee1+" )"
        }
        return "source=https://bano.openstreetmap.fr/pifometre/pifodrome.html%23map=15/"+y+"/"+x+"%7Chashtags=%23BANO %23Pifometre%7Ccomment="+comment
    }
    function check_josm_remote_control(){
        if (localStorage.PreferencesJOSMRemoteControlWarning == undefined){
            localStorage.setItem('PreferencesJOSMRemoteControlWarning','true')
        }
        if (eval(localStorage.PreferencesJOSMRemoteControlWarning)){
            $.ajax({
                url: "http://127.0.0.1:8111/version"
            })
            .done(function(data){
                if (data){
                    console.log('Télécommande JOSM OK')
                }
            })
            .fail(function(data){
                if($('#alerte_josm').css('visibility') == 'hidden') {
                    $('#alerte_josm').css('visibility','visible');
                    $('#dont_show_josm_alert').prop('checked', false);
                }
                else {
                    $('#alerte_josm').addClass('clignote');
                    setTimeout(function(){
                        $('#alerte_josm').removeClass('clignote');
                    },1000);                }
                //alert("La télécommande JOSM ne répond pas.\nCertains liens sur la page nécessitent que JOSM soit démarré avec la télécommande activée\n\nPour de l'aide sur la télécommande : https://josm.openstreetmap.de/wiki/Help/Preferences/RemoteControl")
            })
        } else {
            console.log("Pas de controle du lancement de JOSM. Pour changer ce réglage : Menu > Préférences")
        }
    }
    function get_labels_statut_fantoir(){
        STATUS_FANTOIR = []
        a_menus_labels = []
        $.ajax({
            url: "labels_statut_fantoir.py",
            async: false
        })
        .done(function( data ) {
            for (c=0;c<data.length;c++){
                menu_labels = '<select>'
                id_label = 0
                for (i=0;i<data.length;i++){
                    if (c!=i){
                        menu_labels+='<option value='+data[i][0]+'>'+data[i][1]+'</option>'
                    } else {
                        menu_labels+='<option value='+data[i][0]+' selected>'+data[i][1]+'</option>'
                        id_label = data[i][0]
                    }
                }
                STATUS_FANTOIR.push('statut'+c)
                menu_labels+='</select>'
                a_menus_labels[id_label] = menu_labels
            }
        })
        return [a_menus_labels,STATUS_FANTOIR]
    }
    function add_statut_fantoir(table,id_ligne,fantoir,id_statut){
        $('#'+table+' tr:last').removeClass(STATUS_FANTOIR).addClass('statut'+id_statut)
        $('#'+table+' tr:last').append($('<td class="cell_statut">').append($(a_menus_labels[id_statut]).change(function() {
            code_insee = fantoir.substr(0,5);
            statut = $(this)[0].value;
            $.ajax({
                url: "statut_fantoir.py?insee="+code_insee+"&fantoir="+fantoir+"&statut="+statut
            })
            .done(function( data ) {
                if(data == statut){
                    $('tr#'+id_ligne).removeClass(STATUS_FANTOIR).addClass('statut'+statut)

                    //Afficher l'infobulle de confirmation
                    if (statut != '0') {
                        $('tr#'+id_ligne+' td.cell_statut').append($('<span class="enregistrement voies gris">').text('✔'));
                    }
                    else {
                        $('tr#'+id_ligne+' td.cell_statut').append($('<span class="enregistrement voies vert">').text('✔'));
                    }
                    setTimeout(function(){
                        $('tr#'+id_ligne+' td.cell_statut span').css('opacity', '1');
                        setTimeout(function(){
                            $('tr#'+id_ligne+' td.cell_statut span').css('opacity', '0');
                        }, 1500);
                        setTimeout(function(){
                            $('tr#'+id_ligne+' td.cell_statut span').remove();
                        }, 2000);
                    }, 50);

                } else {
                    alert("Souci lors de la mise à jour du statut. Le nouveau statut n'a pas été pris en compte")
                }
            })
        })))
    }

    function parse_pifometre(categorie,caractere_annul,fantoir) {
        is_voie = false
        is_place = false
        has_vrai_code_fantoir = true
        is_osm_hors_fantoir = false
        if (categorie == 0){
            is_voie = true;
        } else if (categorie == 1){
            is_place = true;
        } else if (categorie == 2){
            is_osm_hors_fantoir = true;
        }
        fantoir_affiche = fantoir
        fantoir_dans_relation = 'ok'
        if ('BCTF'.indexOf(caractere_annul) > -1){
            has_vrai_code_fantoir = false
            fantoir_affiche = 'Sans Fantoir'
            fantoir_dans_relation = 'ko'
        }
        return [is_voie,is_place,is_osm_hors_fantoir,has_vrai_code_fantoir,fantoir_affiche,fantoir_dans_relation]
    }
    function get_fantoir_affiche(fantoir){
        if (fantoir.includes('b')){
            return 'Sans Fantoir'
        }
        return fantoir
    }

    function autocomplete_commune(v,from) {
        let selectedIndex = -1; // Track the selected index for keyboard navigation

        v_norm = v.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '')
        if (v.length < 3 && v_norm.match("y|ay|by|bu|eu|fa|gy|oz|oo|py|ri|ry|sy|ur|us|uz") == null) {
            $('#listeSuggestions').empty().css("display","none"); // Vider la liste existante
            return;
        }
        let url_to_call = ''
        if (/^[0-9]*[ab]?[0-9]*$/.test(v)) {
            // Si la valeur est compatible avec un code INSEE, on ne fait pas de requête AJAX
            return
        } else {
            //on suppose que c'est un début de nom de commune
            url_to_call = 'https://geo.api.gouv.fr/communes?fields=code&boost=population&fields=nom&nom=' + encodeURIComponent(v_norm)
        }
        $.ajax({
            url: url_to_call
        })
        .done(function(data) {
                $('#listeSuggestions').empty().css("display","block"); // Vider la liste existante
                selectedIndex = -1;

                if (data.length == 0) {
                    $('#listeSuggestions').append('<div value="">Aucune commune trouvée</div>');
                } else {
                    data = autocomplete_PLM(data)
                    data = autocomplete_sort(data,v_norm)
                    for (i=0;i<Math.min(NB_SUGGESTIONS_MAX,data.length);i++){
                        nom_affiche = autocomplete_format(data[i].nom,v_norm)
                        $('#listeSuggestions').append($('<div class="item">').attr("value",data[i].code)
                                                            .append(data[i].code+' '+nom_affiche)
                                                            .click(function(){
                                                                $('#input_insee').empty()
                                                                $('#input_insee')[0].value = $(this).attr('value')
                                                                if (from == 'pifometre'){
                                                                    requete_pifometre()
                                                                }
                                                                else if (from == 'pifomap') {
                                                                    reset_url_hash();
                                                                    reset_panneau_map();
                                                                    requete_pifometre();
                                                                }
                                                                else if (from == 'sources') {
                                                                    listing_fantoir();
                                                                }
                                                                $("#listeSuggestions").css('display','none');
                                                            }));
                    }
                }
                // Fermer si on clique dehors
                $(document).on("click", function (e) {
                    if (!$(e.target).closest("#listeSuggestions").length) {
                        $("#listeSuggestions").css('display','none');
                    }
                });
                //Navigation au clavier
                $("#input_insee").off().on("keydown", function (e) {
                    let items = $("#listeSuggestions .item");
                    if (items.length === 0) return;

                    if (e.key === "ArrowDown") {
                        e.preventDefault();
                        selectedIndex = (selectedIndex + 1) % items.length;
                        items.removeClass("active").eq(selectedIndex).addClass("active");
                    } else if (e.key === "ArrowUp") {
                        e.preventDefault();
                        selectedIndex = (selectedIndex - 1 + items.length) % items.length;
                        items.removeClass("active").eq(selectedIndex).addClass("active");
                    } else if (e.key === "Enter") {
                        e.preventDefault();
                        if (selectedIndex >= 0 && !items.eq(selectedIndex).hasClass("rien")) {
                            $('#input_insee').empty()
                            $('#input_insee')[0].value = items.eq(selectedIndex).attr('value')
                            if (from == 'pifometre'){
                                requete_pifometre()
                            }
                            else if (from == 'pifomap') {
                                reset_url_hash();
                                reset_panneau_map();
                                requete_pifometre();
                            }
                            else if (from == 'sources') {
                                listing_fantoir();
                            }
                            $('#listeSuggestions').empty().css("display","none"); // Vider la liste existante
                        }
                    }
                    if (e.key === "Escape") {
                        $("#listeSuggestions").css('display','none');
                    }
                });
        })
        .fail(function() {
                alert('Erreur lors du chargement des options.');
            }
        );
    }
    function autocomplete_normalize(s){
        return s.toLowerCase().replaceAll("-"," ").normalize('NFD').replace(/[\u0300-\u036f]/g, '')
    }
    function autocomplete_sort(ajax_resp, saisie_norm){
        res_exact = []
        res_partiel = []
        res_desordre = []
        for (i=0;i<ajax_resp.length;i++){
            ajax_resp[i].index = autocomplete_normalize(ajax_resp[i].nom).indexOf(saisie_norm)
            if (autocomplete_normalize(ajax_resp[i].nom) == saisie_norm){
                res_exact.push(ajax_resp[i])
            } else if (ajax_resp[i].index > -1){
                res_partiel.push(ajax_resp[i])
            } else {
                res_desordre.push(ajax_resp[i])
            }
        }
        res_exact.sort(function(a, b){return Number((a.nom+a.code)>(b.nom+b.code))})
        res_partiel.sort(function(a, b){
            if (a.index > b.index){
                return 1
            }
            if (a.index < b.index){
                return -1
            }
            if (a.code > b.code){
                return 1
            }
            return -1
        })
        return (res_exact.concat(res_partiel)).concat(res_desordre)
    }
    function autocomplete_format(nom,saisie_norm){
        nom_norm = autocomplete_normalize(nom)
        r = new RegExp(saisie_norm)
        position = nom_norm.search(r)
        if (position > -1) {
            avant = nom.slice(0,position)
            saisie = nom.slice(position,position+saisie_norm.length)
            apres = nom.slice(position+saisie_norm.length)
            return(avant+'<span class="saisie">'+saisie+'</span>'+apres)
        }
        // a_saisie_norm = saisie_norm.split(' ')
        // for (i=0;i<a_saisie_norm.length;i++){
        //     g = a_saisie_norm[i]
        //     index = 0
        //     while(nom_norm.indexOf(g,index) > -i)
        // }
        return nom
    }
    function autocomplete_PLM(ajax_resp){
        res = []
        for (i=0;i<ajax_resp.length;i++){
            if (autocomplete_normalize(ajax_resp[i].code).match("13055|69123|75056") != null){
                plm = new Map([['75056',[20,75100]],
                               ['69123',[9,69380]],
                               ['13055',[16,13200]]])

                for (a=1;a<plm.get(ajax_resp[i].code)[0]+1;a++){
                    res.push({nom:ajax_resp[i].nom+' '+a+'e arrdt',code:plm.get(ajax_resp[i].code)[1]+a})
                }
            } else {
                res.push(ajax_resp[i])                
            }
        }
        return res
    }
    function add_context_menu(){
        map.on('contextmenu', (e) => {
            if (typeof e.features == 'undefined'){
                lon = e.lngLat.lng
                lat = e.lngLat.lat
                $.ajax({
                    url: "insee_from_coords.py?lat="+lat+"&lon="+lon
                })
                .done(function( data ) {
                    code_insee = data[0][0]
                    nom_commune = data[0][1]
                        xmin  = lon-DELTA*4
                        xmax  = lon+DELTA*4
                        ymin  = lat-DELTA*2
                        ymax  = lat+DELTA*2
                        table = 'popup_table_liens'

                        if (context_menu !== null){
                            context_menu.remove()
                        }
                        context_menu = new maplibregl.Popup({anchor:'top-left'})
                                        .setLngLat(e.lngLat)
                                        .setHTML('<div id="contenu_popup_context">')
                                        .addTo(map);

                        $('#contenu_popup_context')
                                .append($('<h2>').text(nom_commune))
                        page = window.location.href.split('?')[0].split('#')[0].split('/').pop()
                        if (page == 'pifomap.html'){
                            if ($('#input_insee')[0].value != code_insee){
                                $('#contenu_popup_context')
                                    .append($('<div class="item_context_menu">').text('Charger la commune').click(function(){
                                        $('#input_insee')[0].value = code_insee
                                        reset_panneau_map();
                                        requete_pifometre();
                                    }))
                            }
                        } else {
                            $('#contenu_popup_context').append($('<a>').attr('target','blank')
                                                                   .attr('href','pifomap.html?insee='+code_insee+'#map=17/'+lat+'/'+lon)
                                                                   .append($('<div class="item_context_menu">').text('Pifomap')))
                        }

                        // Tags de changeset selon la page
                        if (page == 'pifodrome.html'){
                            changeset_tags = get_changeset_tags_croisement(lon,lat,nom_commune,code_insee)
                        } else {
                            changeset_tags = get_changeset_tags_noms(code_insee,nom_commune)
                        }
                        // Historique de visite au clic uniquement si Pifodrome
                        if (page == 'pifodrome.html'){
                            update_storage_visits(nom_commune,-9999,'Pifodrome',window.location.pathname,'noparam',location.hash,VERSION_MENU)
                            update_menu_visits()
                        }

                        $('#contenu_popup_context').append($('<hr>'))
                                                   .append($('<a>').attr('target','blank')
                                                                   .attr('href','./liste_brute_fantoir.html?insee='+code_insee)
                                                                   .append($('<div class="item_context_menu">').text('Topo')))
                                                   .append($('<a>').attr('target','blank')
                                                                   .attr('href','index.html?insee='+code_insee)
                                                                   .append($('<div class="item_context_menu">').text('Pifomètre')))

                                                   .append($('<hr>'))
                                                   .append($('<a>').attr('target','blank')
                                                                   .attr('href','http://www.openstreetmap.org/edit?editor=id#map=18/'+lat+'/'+lon)
                                                                   .append($('<div class="item_context_menu">').text('Éditer sur ID')))
                                                   .append($('<div class="item_context_menu">').text('Éditer sur JOSM')
                                                                                               .click(function(){
                                                            srcLoadAndZoom = 'http://127.0.0.1:8111/load_and_zoom?left='+xmin+'&right='+xmax+'&top='+ymax+'&bottom='+ymin+'&changeset_tags='+changeset_tags;
                                                            $('<img>').appendTo($('#josm_target')).attr('src',srcLoadAndZoom);
                                                            $(this).addClass('clicked');
                                                            })
                                                    )
                        // WIP Rafraichissement des tuiles PBF uniquement si Pifodrome
                        // if (page == 'pifodrome.html'){
                        //     $('#contenu_popup_context').append($('<hr>'))
                        //                                .append($('<div id="menu_maj_pbf" class="item_context_menu">').text('Màj des tuiles'))
                        //     $('#menu_maj_pbf').click(function(){
                        //         refresh_pifodrome_pbf(lon,lat)
                        //     })
                        // }
                })
            }
        })
    }
    function refresh_pifodrome_pbf(lon,lat){
        $('body').css('cursor','progress');
        $('#wait_ajax').empty()
                       .css('visibility','visible')
                       .append($('<span>').append('Mise à jour des tuiles vectorielles en cours...'));
        $('#wait_ajax_mobile').css('visibility','visible');
        $.ajax({
            url: "pifodrome_refresh_pbf.py?lon="+lon+'&lat='+lat,
        })
        .done(function( data ){
            if (data == '1'){
                $('#wait_ajax').empty()
                       .append($('<span>').append('Mise à jour des tuiles vectorielles OK'));
            } else {
                alert('Problème lors de la mise à jour')
            }
            $('body').css('cursor','default');
            $('#wait_ajax').css('visibility','hidden');
            $('#wait_ajax_mobile').css('visibility','hidden');
        })
    }
    function reset_url_hash(){
        history.replaceState("", "", window.location.pathname+"?"+window.location.search.replace(/\?/g,'')+'&reset=reset')
    }
    function affiche_ratio_map() {
        hash_value = ''
        if ($('#radio_prog_noms').is(':checked')) {
            affiche_ratio_noms()
            hash_value = 'N'
        }
        if ($('#radio_prog_noms_avec_adresses').is(':checked')) {
            affiche_ratio_noms_adresses()
            hash_value = 'NA'
        }
        if ($('#radio_prog_adresses').is(':checked')) {
            affiche_ratio_numeros()
            hash_value = 'A'
        }
        if (hash_value != ''){
            update_search('ratio',hash_value)
        }
    }
    function update_search(key,value){
        before_key = window.location.search.split(key+'=')[0]
        if (before_key == ''){
            before_key = '?'
        }
        after_key_str = ''
        if (window.location.search.includes(key+'=')){
            after_key = window.location.search.split(key+'=')[1].split('&')
            if (after_key.length > 1){
                after_key.shift()
                after_key_str = '&'+after_key.join('&')
            }
        } else {
            if (before_key != '?'){
                before_key += '&'
            }
        }
        history.replaceState("", "", window.location.pathname+before_key+key+'='+value+after_key_str+window.location.hash)
    }

    function affiche_ratio_numeros(){
        map.setLayoutProperty('point_de_communes','visibility','visible')
        map.setPaintProperty('point_de_communes','circle-color',["interpolate",["linear"],["/", ["*",["get", "nb_adresses_osm"],100],["get", "nb_adresses_ban"]],0,"red",25,"orange",50,"yellow",75,"green"])
    }
    function affiche_ratio_noms_adresses(){
        map.setLayoutProperty('point_de_communes','visibility','visible')
        map.setPaintProperty('point_de_communes','circle-color',["interpolate",["linear"],["/", ["*",["get", "nb_nom_adr_osm"],100],["get", "nb_noms_ban"]],0,"red",25,"orange",50,"yellow",75,"green"])
    }
    function affiche_ratio_noms(){
        map.setLayoutProperty('point_de_communes','visibility','visible')
        map.setPaintProperty('point_de_communes','circle-color',["interpolate",["linear"],["/", ["*",["get", "nb_noms_osm"],100],["get", "nb_noms_topo"]],0,"red",25,"orange",50,"yellow",75,"green"])
    }
    function update_radio_ratio(){
        ratio = check_url_for_ratio_map()
        if (ratio == 'N'){
            $('#radio_prog_noms').click()
        } else if (ratio == 'A'){
            $('#radio_prog_adresses').click()
        } else if (ratio == 'NA'){
            $('#radio_prog_noms_avec_adresses').click()
        } else {
            update_search('ratio','no')
        }
    }
    function device_is_mobile(){
        ua = navigator.userAgent.toLowerCase()
        if (ua.includes('android')||ua.match(/iphone/)||ua.match(/ipod/)||ua.match(/ipad/)){
            return true
        }
        return false
    }
    function getLocation() {
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(localise_moi);
        } else {
            console.log("Pas de geolocalisation disponible");
        }
    }
    function update_storage_visits(name,code,type,page,parametre,hash,version){
        const v = {nom:name,code:code,type:type,page:page,parametre:parametre,hash:hash,version:version}
        if (localStorage.visits == undefined){
            localStorage.setItem('visits',JSON.stringify([v]))
        }
        visits = JSON.parse(localStorage.visits)
        indice = -1
        for (i=0;i<visits.length;i++){
            if (visits[i].code == code && visits[i].type == type){
                indice = i
            }
        }
        if (indice > -1){
            visits.splice(indice,1)
        }
        visits.unshift(v)
        if (visits.length > 5){
            visits = visits.slice(0,5)
        }
        localStorage.setItem('visits',JSON.stringify(visits))
    }
    function update_menu_visits(){
        if (localStorage.visits != undefined){
            $('#menu_recent #liens').empty()
            visits = JSON.parse(localStorage.visits)
            for (i=0;i<visits.length;i++){
                search = ''
                hash = ''
                if (visits[i].version == VERSION_MENU ){
                    if (visits[i].code != '-9999'){
                        search = '?'+visits[i].parametre+'='+visits[i].code
                    }
                    if (visits[i].hash != undefined){
                        hash = visits[i].hash
                    }
                    $('#menu_recent #liens').append($('<h2>').append($('<a>').attr('href',visits[i].page+search+hash).append(visits[i].nom+' - '+visits[i].type)))
                }
            }
        }
    }
    function initPreferences(){
        // General : Telecommande JOSM
        if (localStorage.PreferencesJOSMRemoteControlWarning == undefined){
            localStorage.setItem('PreferencesJOSMRemoteControlWarning','true')
        }

        // Général : bouton Copier
        if (localStorage.PreferencesCopierCleValeur == undefined){
            localStorage.setItem('PreferencesCopierCleValeur','false')
        }

        // Général : relations associatedStreet
        if (localStorage.PreferencesAddrRelation == undefined){
            localStorage.setItem('PreferencesAddrRelation','false')
        }

        // Général : voies en schema Point
        if (localStorage.PreferencesAddrRueAvecPoints == undefined){
            localStorage.setItem('PreferencesAddrRueAvecPoints','false')
        }

        // Pifometre : pagination des résultats
        if (localStorage.PreferencesPifometreAffichage_pagine == undefined){
                localStorage.setItem('PreferencesPifometreAffichage_pagine',-1)
                localStorage.setItem('PreferencesPifometreAffichage_pagineRadioId','non')
            }
        }

        // Pifomap : Masquage des lieux-dits
        if (localStorage.PreferencesPifomapMasquage_lieuxditsTerme == undefined){
            localStorage.setItem('PreferencesPifomapMasquage_lieuxditsTerme',-1)
            localStorage.setItem('PreferencesPifomapMasquage_lieuxditsRadioId','jamais')
        }
