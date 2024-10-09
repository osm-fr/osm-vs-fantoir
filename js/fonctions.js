    let hoveredStateId = null;
    let context_menu = null;

    function is_valid_dept(d){
        pattern_dept = new RegExp('^([01]|[3-8])([0-9])$|^2([aAbB]|[1-9])$|^9([0-5]|7[1-4]|76)$')
        res = false
        if (pattern_dept.test(d)){
            res = d
        }
        return res
    }
    function get_dept_from_insee(code_insee){
        if (code_insee.substr(0,2) == '97'){
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
        $('#'+table+' tr:last')     .append($('<td>').addClass('zone-clic-id')
                                        .append($('<a>').attr('href',href).attr('target',"blank")                                    
                                            .text(text)
                                        )
                                        .click(function(){
                                            $(this).addClass('clicked');
                                        })
                                    )
    }
    function add_josm_link(table,xl,xr,yb,yt,code_insee,nom_commune){
        $('#'+table+' tr:last').append($('<td>').addClass('zone-clic-josm')
                                    .attr('xleft',xl).attr('xright',xr).attr('ybottom',yb).attr('ytop',yt)
                                    .text('JOSM')
                                    .click(function(){
                                        srcLoadAndZoom = 'http://127.0.0.1:8111/load_and_zoom?left='+xl+'&right='+xr+'&top='+yt+'&bottom='+yb+'&changeset_tags='+get_changeset_tags_noms(code_insee,nom_commune);
                                        $('<img>').appendTo($('#josm_target')).attr('src',srcLoadAndZoom);
                                        $(this).addClass('clicked');
                                    })
                                )
    }
    function add_josm_croisement_link(table,xl,xr,yb,yt,commune1,insee1,commune2,insee2,wayid){
        $('#'+table+' tr:last').append($('<td>').addClass('zone-clic-josm')
                                    .attr('xleft',xl).attr('xright',xr).attr('ybottom',yb).attr('ytop',yt)
                                    .text('JOSM')
                                    .click(function(){
                                        srcLoadAndZoom = 'http://127.0.0.1:8111/load_and_zoom?left='+xl+'&right='+xr+'&top='+yt+'&bottom='+yb+'&select=way'+wayid+'&changeset_tags='+get_changeset_tags_croisement((xl+xr)/2,(yb+yt)/2,commune1,insee1,commune2,insee2);
                                        $('<img>').appendTo($('#josm_target')).attr('src',srcLoadAndZoom);
                                        $(this).addClass('clicked');
                                    })
                                )
    }
    function add_josm_addr_link(table,code_insee,nom_commune,fantoir,nom_fantoir,nombre,fantoir_dans_relation,is_place){
        stringToRemove = window.location.href.split('?')[0].split('/').pop()
        $('#'+table+' tr:last').append($('<td>').addClass('zone-clic-adresses'))
        $('#'+table+' tr:last td:last').append($('<span>').text(nombre > 1 ? nombre+' Points':'1 Point'))
                                            .click(function(){
                                                srcURL = 'http://127.0.0.1:8111/import?changeset_tags='+get_changeset_tags_addr(code_insee,nom_commune)+'&new_layer=true&layer_name='+nom_fantoir+'&url='+window.location.href.split('?')[0].replace(stringToRemove,'')+'requete_numeros.py?insee='+code_insee+'&fantoir='+fantoir+'&modele='+((is_place) ? 'Place':'Points');
                                                $('<img>').appendTo($('#josm_target')).attr('src',srcURL);
                                                $(this).addClass('clicked');
                                            })
        if (is_place){
            $('#'+table+' tr:last td:last').attr('colspan','2').append($('<span>').text(' (lieu-dit)'))
        } else {
            $('#'+table+' tr:last').append($('<td>').addClass('zone-clic-adresses').append($('<span>'))
                                        .text('Relation')
                                        .click(function(){
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
                                        .click(function(){
                                            $(this).addClass('clicked');
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
        return "source=https://bano.openstreetmap.fr/pifometre/croisement_voies_limites.html%23map=15/"+y+"/"+x+"%7Chashtags=%23BANO %23Pifometre%7Ccomment=Correction des rues et routes à cheval entre "+commune1+" ("+insee1+" ) et "+commune2+" ("+insee2+")"
    }
    function check_josm_remote_control(){
        $.ajax({
            url: "http://127.0.0.1:8111/version"
        })
        .done(function(data){
            if (data){
                console.log('Télécommande JOSM OK')
            }
        })
        .fail(function(data){
            alert("La télécommande JOSM ne répond pas.\nCertains liens sur la page nécessitent que JOSM soit démarré avec la télécommande activée\n\nPour de l'aide sur la télécommande : https://josm.openstreetmap.de/wiki/Help/Preferences/RemoteControl")
        })
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
                        $('tr#'+id_ligne+' td.cell_statut').append($('<span class="enregistrement voies gris">').text('✔ Enregistré'));
                    }
                    else {
                        $('tr#'+id_ligne+' td.cell_statut').append($('<span class="enregistrement voies vert">').text('✔ Enregistré'));
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
        has_code_fantoir = true
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
        if (caractere_annul == 'B'){
            has_code_fantoir = false
            fantoir_affiche = 'Voie sans Fantoir'
            fantoir_dans_relation = 'ko'
        }
        return [is_voie,is_place,is_osm_hors_fantoir,has_code_fantoir,fantoir_affiche,fantoir_dans_relation]
    }
    function get_fantoir_affiche(fantoir){
        if (fantoir.includes('b')){
            return 'Voie sans Fantoir'
        }
        return fantoir
    }
    function interactions_souris(couche_carto){
        //-----------------------------------------------
        //---------------- RAZ PANNEAU ------------------
        //-----------------------------------------------
        if (couche_carto == 'simple-tiles'){
            map.on('click', (e) => {
                if (typeof e.features == 'undefined'){
                    reset_panneau_map()
                }
            })
        }
        //-----------------------------------------------
        //---------------- CLIC DROIT -------------------
        //-----------------------------------------------
        if (couche_carto == 'simple-tiles'){
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
                            if ($('#input_insee')[0].value != code_insee){
                                $('#contenu_popup_context')
                                    .append($('<div class="item_context_menu">').text('Charger la commune').click(function(){
                                        $('#input_insee')[0].value = code_insee
                                        reset_panneau_map();
                                        requete_pifometre();
                                    }))
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
                                                                srcLoadAndZoom = 'http://127.0.0.1:8111/load_and_zoom?left='+xmin+'&right='+xmax+'&top='+ymax+'&bottom='+ymin+'&changeset_tags='+get_changeset_tags_noms(code_insee,nom_commune);
                                                                $('<img>').appendTo($('#josm_target')).attr('src',srcLoadAndZoom);
                                                                $(this).addClass('clicked');
                                                                })
                                                        )
                    })
                }
            })
        }

        //-----------------------------------------------
        //------------------ AU SURVOL ------------------
        //-----------------------------------------------
        if (couche_carto == 'noms_de_communes'){
            for (i=1;i<4;i++){
                map.on('mouseenter', couche_carto+'_'+i, (e) => {
                    // Changer le curseur
                    map.getCanvas().style.cursor = 'pointer';
                });
                map.on('mouseleave', couche_carto+'_'+i, () => {
                    map.getCanvas().style.cursor = '';
                });
            }
        }
        if (couche_carto == 'BAN_point_transparent'||
            couche_carto == 'OSM_point'||
            couche_carto == 'filaire_transparent'||
            couche_carto.indexOf('points_nommes_') == 0){
            map.on('mouseenter', couche_carto, (e) => {
                // Changer le curseur
                map.getCanvas().style.cursor = 'pointer';

                nom = e.features[0].properties.nom;
                fantoir = e.features[0].properties.fantoir;
                hoveredStateId = fantoir
                map.setFeatureState({
                      source: 'points_nommes',
                      id: fantoir,
                    }, {
                      hover: true
                    });

                map.setFilter('filaire',["==",["get", "nom"], nom])
                map.setFilter('filaire_texte',["==",["get", "nom"], nom])
                if (fantoir != ''){
                    map.setFilter('hover_points',["any",["==",["get", "fantoir"], fantoir],["==",["get", "nom"], nom]])
                } else {
                    map.setFilter('hover_points',["==",["get", "nom"], nom])
                }

                if (e.features.length > 1){
                    if (e.features[0].properties.nom != e.features[1].properties.nom){
                        textfield = ["format",e.features[0].properties.nom,{"font-scale": 0.9}]

                        for (i=1;i<e.features.length;i++){
                            textfield.push('\n',{},e.features[i].properties.nom,{"font-scale": 0.9})
                        }
                        map.setLayoutProperty('filaire_texte','text-field',textfield)
                        map.setLayoutProperty('filaire_texte','symbol-placement','point')
                    }
                }
            });

            map.on('mouseleave', couche_carto, (e) => {
                if (hoveredStateId){
                    map.setFeatureState({
                          source: 'points_nommes',
                          id: hoveredStateId,
                        }, {
                          hover: false
                        });
                }

                map.getCanvas().style.cursor = '';
                map.setFilter('filaire',["==",["get", "nom"], " "])
                map.setFilter('filaire_texte',["==",["get", "nom"], " "])
                map.setFilter('hover_points',["==",["get", "fantoir"], "xxxxxxxxx"])

            // RAZ du texte multi-noms
                map.setLayoutProperty('filaire_texte','text-field',["get", "nom"])
                map.setLayoutProperty('filaire_texte','symbol-placement','line')
            });
        }

        //---------------------------------------------
        //------------------ AU CLIC ------------------
        //---------------------------------------------

        //--------------------------------
        //------- NOMS DE COMMUNES -------
        //--------------------------------

        if (couche_carto == 'noms_de_communes'){
            for (i=1;i<4;i++){
                map.on('click', couche_carto+'_'+i, (e) => {
                    code_insee = e.features[0].properties.code_insee;
                    location.assign(window.location.pathname+"?insee="+code_insee)
                });
            }
        }
        //----------------------------------------------------------------------------------
        //------- POINTS D'ADRESSE et NOMS DE VOIES OU LIEUX-DITS RAPPROCHES (VERTS) -------
        //----------------------------------------------------------------------------------

        if (couche_carto == 'BAN_point_transparent' || couche_carto == 'OSM_point' || couche_carto.indexOf('points_nommes_rapproches') == 0){
            map.on('click', couche_carto, (e) => {

                nom = e.features[0].properties.nom;
                numero = e.features[0].properties.numero;
                source = e.features[0].properties.source;
                rapproche = e.features[0].properties.rapproche;
                nom_commune = e.features[0].properties.nom_com;
                lon = e.lngLat.lng
                lat = e.lngLat.lat

                reset_panneau_map()

                if (couche_carto == 'BAN_point_transparent' || couche_carto == 'OSM_point') {
                    $('#panneau_map h2').attr('texte_a_copier',nom).text(numero+' '+nom)
                } else {
                    $('#panneau_map h2').attr('texte_a_copier',nom).text(nom)
                }
                $('#panneau_map #espace_bouton_copier').append('<button id="copier_voie" title="Copier le nom de la voie"></button>')
                $('#panneau_map #espace_bouton_copier #copier_voie').click(function(){

                    //Copie le nom de la voie dans le presse-papier
                    navigator.clipboard.writeText($('#panneau_map h2').attr('texte_a_copier'))
                    //Affiche le picto copie en vert
                    $(this).addClass('ok')
                    //Affiche le message de confirmation
                    $('#panneau_map #espace_bouton_copier').append($('<span id="confirmation_copie">').text('✔ Copié'));

                    setTimeout(function(){
                        $('#panneau_map #espace_bouton_copier #confirmation_copie').css('opacity', '1');
                        setTimeout(function(){
                            $('#panneau_map #espace_bouton_copier #confirmation_copie').css('opacity', '0');
                        }, 800);
                        setTimeout(function(){
                            $('#panneau_map #espace_bouton_copier #confirmation_copie').remove();
                        }, 1500);
                    }, 50);

                })

                fantoir = e.features[0].properties.fantoir;

                // Adresses rattachées à une voie OSM seule (liste bleue)
                if (!fantoir){
                    $('#infos_numero').append($('<p>').text("Cette adresse (numéro + nom de voie ou lieu-dit) est issue d'OSM et elle est inconnue de la BAN. Son nom est aussi inconnu de Fantoir."));

                    //LIENS DE VISU

                    $('#infos_voie_lieudit').append($('<hr>'));
                    $('#infos_voie_lieudit').append($('<h3>').text('Voir le lieu sur : '));

                    $('#infos_voie_lieudit').append($('<ul>')
                                                .append($('<li>')
                                                    .append($('<a>')
                                                        .attr('href',url_map_org_part1+'?mlat='+lat+'&mlon='+lon+'#map='+'18/'+lat+'/'+lon)
                                                        .attr('target','blank')
                                                        .text('ORG')
                                                    )
                                                )
                                            );

                    //LIENS D'EDITION

                    $('#infos_voie_lieudit').append($('<hr>'));
                    $('#infos_voie_lieudit').append($('<h3>').text('Édition'));

                    xmin  = lon-DELTA
                    xmax  = lon+DELTA
                    ymin  = lat-DELTA
                    ymax  = lat+DELTA

                    table = 'pifomap_table_liens'
                    $('#'+table).append($('<tr>').append($('<td>').attr('colspan','2').append($('<span class="gras">').text('Éditer la zone sur'))))
                    $('#'+table).append($('<tr>'))
                    add_josm_link(table,xmin,xmax,ymin,ymax,code_insee,nom_commune)
                    add_id_link(table,'http://www.openstreetmap.org/edit?editor=id#map=18/'+lat+'/'+lon,'ID')

                    return 0
                }

                // cas général
                code_insee = fantoir.substring(0,5)

                $.ajax({
                    url: "requete_pifometre_voies.py?insee="+code_insee+'&fantoir='+fantoir
                })
                .done(function( data ) {
                    let [fantoir,
                         date_creation,
                         annule,
                         nom_topo,
                         nom_osm,
                         nom_ban,
                         source_nom_ban,
                         nom_ancienne_commune,
                         lon,
                         lat,
                         statut_voie,
                         numeros_a_proposer,
                         caractere_annul,
                         categorie,
                         avec_adresses_ban] = data[0]

                    let [is_voie,
                        is_place,
                        is_osm_hors_fantoir,
                        has_code_fantoir,
                        fantoir_affiche,
                        fantoir_dans_relation] = parse_pifometre(categorie,caractere_annul,fantoir)

                        //Mettre à jour le nom de la rue
                        if (nom_osm != null){
                            if (couche_carto == 'BAN_point_transparent' || couche_carto == 'OSM_point') {
                                $('#panneau_map h2').attr('texte_a_copier',nom_osm).text(numero+' '+nom_osm)
                            } else {
                                $('#panneau_map h2').attr('texte_a_copier',nom_osm).text(nom_osm)
                            }
                        }

                        //Infos sur le numéro
                        if (couche_carto == 'BAN_point_transparent' || couche_carto == 'OSM_point') {
                            $('#infos_numero').append($('<h3>').text('Le point d\'adresse :'));

                            $('#infos_numero').append($('<ul>'));

                            $('#infos_numero ul').append($('<li>')
                                                        .append($('<span class="gras">').text('Numéro : '))
                                                        .append($('<span>').text(numero))
                                                    );
                            $('#infos_numero ul').append($('<li>')
                                                            .append($('<span class="gras">').text('Source du point : '))
                                                            .append($('<span>').text(source))
                                                    );

                            if (is_place) {
                                $('#infos_numero ul').append($('<li>')
                                                            .append($('<span class="gras">').text('Rattaché à : '))
                                                            .append($('<span>').text('un lieu-dit'))
                                                        );
                            }
                            else {
                                $('#infos_numero ul').append($('<li>')
                                                            .append($('<span class="gras">').text('Rattaché à : '))
                                                            .append($('<span>').text('une voie'))
                                                        );
                            }                        
                            $('#infos_numero').append($('<hr>'));
                        }

                        //Infos sur la voie ou le lieu-dit

                        e_terminal = 'e'
                        if (is_place) {
                            $('#infos_voie_lieudit').append($('<h3>').text('Lieu-dit :'));
                            e_terminal = ''
                        } else {
                            $('#infos_voie_lieudit').append($('<h3>').text('Voie :'));
                        }

                        if (rapproche) {
                            title_text = 'rapproché'+e_terminal+' dans OSM'
                            class_pastille = 'pastille-verte'
                        } else {
                            title_text = 'pas rapproché'+e_terminal+' dans OSM'
                            class_pastille = 'pastille-orange'
                        }

                        $('#infos_voie_lieudit').append($('<ul>'));
                        $('#infos_voie_lieudit ul').append($('<li>')
                                                .append($('<span>').addClass(class_pastille).attr('title',title_text))
                                                .append($('<span>').text(title_text)));


                        $('#infos_voie_lieudit ul').append($('<li>')
                                                        .append($('<span class="gras">').text('Nom OSM : '))
                                                        .append($('<span>').text(nom_osm))
                                                    )
                                                    .append($('<li>')
                                                        .append($('<span class="gras">').text('Nom BAN : '))
                                                        .append($('<span>').text(nom_ban))
                                                    );
                        if (has_code_fantoir) {
                            $('#infos_voie_lieudit ul') .append($('<li>')
                                                            .append($('<span class="gras">').text('Libellé Fantoir : '))
                                                            .append($('<span>').text(nom_topo))
                                                        )
                                                        .append($('<li>')
                                                            .append($('<span class="gras">').text('Code Fantoir : '))
                                                            .append($('<span>').text(fantoir_affiche))
                                                        );
                        }
                        else {
                            $('#infos_voie_lieudit ul') .append($('<li>')
                                                            .append($('<span class="gras">').text('Libellé et code Fantoir : '))
                                                            .append($('<span>').text('/'))
                                                        );
                        }

                        //LIENS DE VISU

                        $('#infos_voie_lieudit').append($('<hr>'));
                        $('#infos_voie_lieudit').append($('<h3>').text('Voir le lieu sur : '));

                        $('#infos_voie_lieudit').append($('<ul>')
                                                    .append($('<li>')
                                                        .append($('<a>')
                                                            .attr('href',url_map_org_part1+'?mlat='+lat+'&mlon='+lon+'#map='+'18/'+lat+'/'+lon)
                                                            .attr('target','blank')
                                                            .text('ORG')
                                                        )
                                                    )
                                                );

                        //LIENS D'EDITION

                        $('#infos_voie_lieudit').append($('<hr>'));
                        $('#infos_voie_lieudit').append($('<h3>').text('Édition'));

                        xmin  = lon-DELTA
                        xmax  = lon+DELTA
                        ymin  = lat-DELTA
                        ymax  = lat+DELTA

                        table = 'pifomap_table_liens'
                        $('#'+table).append($('<tr>').append($('<td>').attr('colspan','2').append($('<span class="gras">').text('Éditer la zone sur'))))
                        $('#'+table).append($('<tr>'))
                            add_josm_link(table,xmin,xmax,ymin,ymax,code_insee,nom_commune)
                            add_id_link(table,'http://www.openstreetmap.org/edit?editor=id#map=18/'+lat+'/'+lon,'ID')
                        
                        if (couche_carto == 'BAN_point_transparent' || couche_carto == 'OSM_point') {
                            if (is_place) {
                                $('#'+table).append($('<tr>').append($('<td>').attr('colspan','2').append($('<span class="gras">').text('Intégrer les adresses dans JOSM'))))
                            }
                            else {
                                $('#'+table).append($('<tr>').append($('<td>').attr('colspan','2').append($('<span class="gras">').text('Intégrer les adresses de la voie dans JOSM'))))
                            }
                            $('#'+table).append($('<tr>'))
                            add_josm_addr_link(table,code_insee,nom_commune,fantoir,nom_topo,numeros_a_proposer,fantoir_dans_relation,is_place)

                            $('#'+table).append($('<tr>').append($('<td>').attr('colspan','2').append($('<span class="gras">').text('Qualifier les adresses sur Pifomètre')))) 
                            $('#'+table).append($('<tr>'))
                            add_addr_inspector_link(table,code_insee,fantoir,'BAN')
                        }
                })
            });
        }

        //-------------------------------------------------------------------
        //------- NOMS DE VOIES OU LIEUX-DITS NON RAPPROCHES (ORANGE) -------
        //-------------------------------------------------------------------

        if (couche_carto.indexOf('points_nommes_non_rapproches') == 0){
            map.on('click', couche_carto, (e) => {
                reset_panneau_map()

                nom = e.features[0].properties.nom;
                fantoir = e.features[0].properties.fantoir;
                rapproche = e.features[0].properties.rapproche;
                source = e.features[0].properties.source;
                nom_commune = e.features[0].properties.nom_com;
                nature = e.features[0].properties.nature;
                lon = e.lngLat.lng
                lat = e.lngLat.lat

                $('#panneau_map h2').attr('texte_a_copier',nom).text(nom)
                $('#panneau_map #espace_bouton_copier').append('<button id="copier_voie" title="Copier le nom de la voie"></button>')
                $('#panneau_map #espace_bouton_copier #copier_voie').click(function(){

                    //Copie le nom de la voie dans le presse-papier
                    navigator.clipboard.writeText($('#panneau_map h2').attr('texte_a_copier'))
                    //Affiche le picto copie en vert
                    $(this).addClass('ok')
                    //Affiche le message de confirmation
                    $('#panneau_map #espace_bouton_copier').append($('<span id="confirmation_copie">').text('✔ Copié'));

                    setTimeout(function(){
                        $('#panneau_map #espace_bouton_copier #confirmation_copie').css('opacity', '1');
                        setTimeout(function(){
                            $('#panneau_map #espace_bouton_copier #confirmation_copie').css('opacity', '0');
                        }, 800);
                        setTimeout(function(){
                            $('#panneau_map #espace_bouton_copier #confirmation_copie').remove();
                        }, 1500);
                    }, 50);
                    
                })

                    //Infos sur la voie ou le lieu-dit

                    e_terminal = 'e'
                    if (nature == "lieudit") {
                        $('#infos_voie_lieudit').append($('<h3>').text('Lieu-dit :'));
                        e_terminal = ''
                    } else {
                        $('#infos_voie_lieudit').append($('<h3>').text('Voie (ou assimilé) :'));
                    }

                    if (source == 'OSM') {
                        title_text = 'connu'+e_terminal+' seulement d\'OSM'
                        class_pastille = 'pastille-bleue'
                    } else {
                        title_text = 'pas rapproché'+e_terminal+' dans OSM'
                        class_pastille = 'pastille-orange'
                    }
                    $('#infos_voie_lieudit').append($('<ul>'));
                    $('#infos_voie_lieudit ul').append($('<li>')
                                                .append($('<span>').addClass(class_pastille).attr('title',title_text))
                                                .append($('<span>').text(title_text)));

                    $('#infos_voie_lieudit ul').append($('<li>')
                                                    .append($('<span class="gras">').text('Source : '))
                                                    .append($('<span>').text(source))
                                            );
                    $('#infos_voie_lieudit ul').append($('<li>')
                                                    .append($('<span class="gras">').text('Code Fantoir : '))
                                                    .append($('<span>').text(fantoir))
                                            );

                    //LIENS DE VISU

                    $('#infos_voie_lieudit').append($('<hr>'));
                    $('#infos_voie_lieudit').append($('<h3>').text('Voir le point sur : '));

                    $('#infos_voie_lieudit').append($('<ul>')
                                                .append($('<li>')
                                                    .append($('<a>')
                                                        .attr('href',url_map_org_part1+'?mlat='+lat+'&mlon='+lon+'#map='+'18/'+lat+'/'+lon)
                                                        .attr('target','blank')
                                                        .text('ORG')
                                                    )
                                                )
                                            );

                    //LIENS D'EDITION

                    $('#infos_voie_lieudit').append($('<hr>'));
                    $('#infos_voie_lieudit').append($('<h3>').text('Édition'));

                    xmin  = lon-DELTA
                    xmax  = lon+DELTA
                    ymin  = lat-DELTA
                    ymax  = lat+DELTA

                    table = 'pifomap_table_liens'
                    $('#'+table).append($('<tr>').append($('<td>').attr('colspan','2').append($('<span class="gras">').text('Éditer la zone sur'))))
                    $('#'+table).append('<tr>')
                    add_josm_link(table,xmin,xmax,ymin,ymax,code_insee,nom_commune)
                    add_id_link(table,'http://www.openstreetmap.org/edit?editor=id#map=18/'+lat+'/'+lon,'ID')
            })
        }
    }
    function reset_url_hash(){
        history.replaceState("", "", window.location.pathname+"?"+window.location.search.replace(/\?/g,''))
    }
    function reset_panneau_map(){
        $('#panneau_map h2').empty()
        $('#panneau_map #espace_bouton_copier').empty()
        $('#infos_numero').empty();
        $('#infos_voie_lieudit').empty();
        $('#pifomap_table_liens').empty();
    }
    function empty_layers(){
        map.getSource('points_nommes').setData(EMPTY_GEOJSON)
        map.getSource('contour_communal').setData(EMPTY_GEOJSON)
        map.getSource('hover_filaire').setData(EMPTY_GEOJSON)
        map.getSource('polygones_convexhull').setData(EMPTY_GEOJSON)
        map.getSource('adresses_OSM').setData(EMPTY_GEOJSON)
        map.getSource('adresses_BAN').setData(EMPTY_GEOJSON)
        map.getSource('hover_points').setData(EMPTY_GEOJSON)
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
        map.setPaintProperty('point_de_communes','icon-color',["interpolate",["linear"],["/", ["*",["get", "nb_adresses_osm"],100],["get", "nb_adresses_ban"]],0,"red",25,"orange",50,"yellow",75,"green"])
    }
    function affiche_ratio_noms_adresses(){
        map.setLayoutProperty('point_de_communes','visibility','visible')
        map.setPaintProperty('point_de_communes','icon-color',["interpolate",["linear"],["/", ["*",["get", "nb_nom_adr_osm"],100],["get", "nb_noms_ban"]],0,"red",25,"orange",50,"yellow",75,"green"])
    }
    function affiche_ratio_noms(){
        map.setLayoutProperty('point_de_communes','visibility','visible')
        map.setPaintProperty('point_de_communes','icon-color',["interpolate",["linear"],["/", ["*",["get", "nb_noms_osm"],100],["get", "nb_noms_topo"]],0,"red",25,"orange",50,"yellow",75,"green"])
    }
    function map_setup(){
        // initialisation du fond raster mémorisé
        if (localStorage.raster == undefined){
            localStorage.setItem('raster','simple-tiles')
        }
        // Fond raster de la dernière session
        set_visible_raster(localStorage.raster)

        map.addControl(new maplibregl.NavigationControl());
        if (!map.hasImage('rond_50')){
            map.loadImage('./img/rond_50.png', (error, image) => {
                map.addImage('rond_50', image, { sdf: true });
            })
        }
        if (!map.hasImage('lieudit_vert')){
            map.loadImage('./img/lieudit_map_vert.png', (error, image) => {
                map.addImage('lieudit_vert', image);
            })
        }
        if (!map.hasImage('lieudit_rouge')){
            map.loadImage('./img/lieudit_map_rouge.png', (error, image) => {
                map.addImage('lieudit_rouge', image);
            })
        }
        if (!map.hasImage('lieudit_bleu')){
            map.loadImage('./img/lieudit_map_bleu.png', (error, image) => {
                map.addImage('lieudit_bleu', image);
            })
        }
        interactions_souris('noms_de_communes')
        interactions_souris('simple-tiles')
        interactions_souris('BAN_point_transparent')
        interactions_souris('OSM_point')
        interactions_souris('filaire_transparent')
        interactions_souris('points_nommes_rapproches_lieudit')
        interactions_souris('points_nommes_non_rapproches_lieudit')
        interactions_souris('points_nommes_rapproches_voie')
        interactions_souris('points_nommes_non_rapproches_voie')

        $('#pifoprogression').click(function(){
            affiche_ratio_map()
        })
        $('#pifofiltres.pifomap input').click(function(){
            update_filtres()
            filtre_pifomap()
        })
        $('#filtre_lieuxdits_mobile input').click(function(){
            filtre_pifomap_mobile()
        })

        update_radio_ratio()
        affiche_ratio_map()
        if (!device_is_mobile()){
            check_josm_remote_control()
        }
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
    function update_storage_visits(name,code,type,page,parametre){
        const v = {nom:name,code:code,type:type,page:page,parametre:parametre}
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
        $('#menu_recent #liens').empty()
        visits = JSON.parse(localStorage.visits)
        for (i=0;i<visits.length;i++){
            $('#menu_recent #liens').append($('<h2>').append($('<a>').attr('href',visits[i].page+'?'+visits[i].parametre+'='+visits[i].code).append(visits[i].nom+' - '+visits[i].type)))
        }

    }