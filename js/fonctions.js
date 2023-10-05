    function is_valid_dept(d){
        pattern_dept = new RegExp('^([01]|[3-8])([0-9])$|^2([aAbB]|[1-9])$|^9([0-5]|7[1-4]|76)$')
        res = false
        if (pattern_dept.test(d)){
            res = d
        }
        return res
    }
    function check_url_for_dept(){
        var res
        if (window.location.hash){
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
            if (window.location.search.split('insee=')[1].split('&')[0]){
                if (pattern_insee.test(window.location.search.split('insee=')[1].split('&')[0])){
                    res = window.location.search.split('insee=')[1].split('&')[0]
                } else {
                    alert(window.location.search.split('insee=')[1].split('&')[0]+' n\'est pas un code INSEE de commune\n\nAbandon')
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
    function add_josm_link(table,xl,xr,yb,yt,insee,nom_commune){
        $('#'+table+' tr:last').append($('<td>').addClass('zone-clic-josm')
                                    .attr('xleft',xl).attr('xright',xr).attr('ybottom',yb).attr('ytop',yt)
                                    .text('JOSM')
                                    .click(function(){
                                        srcLoadAndZoom = 'http://127.0.0.1:8111/load_and_zoom?left='+xl+'&right='+xr+'&top='+yt+'&bottom='+yb+'&changeset_tags='+get_changeset_tags_noms(insee,nom_commune);
                                        $('<img>').appendTo($('#josm_target')).attr('src',srcLoadAndZoom);
                                        $(this).addClass('clicked');
                                    })
                                )
    }
    function add_josm_addr_link(table,insee,nom_commune,fantoir,nom_fantoir,nombre,fantoir_dans_relation,is_place){
        stringToRemove = window.location.href.split('?')[0].split('/').pop()
        $('#'+table+' tr:last').append($('<td>').addClass('zone-clic-adresses'))
        $('#'+table+' tr:last td:last').append($('<span>').text(nombre > 1 ? nombre+' Points':'1 Point'))
                                            .click(function(){
                                                srcURL = 'http://127.0.0.1:8111/import?changeset_tags='+get_changeset_tags_addr(insee,nom_commune)+'&new_layer=true&layer_name='+nom_fantoir+'&url='+window.location.href.split('?')[0].replace(stringToRemove,'')+'requete_numeros.py?insee='+insee+'&fantoir='+fantoir+'&modele='+((is_place) ? 'Place':'Points');
                                                $('<img>').appendTo($('#josm_target')).attr('src',srcURL);
                                                $(this).addClass('clicked');
                                            })
        if (is_place){
            $('#'+table+' tr:last td:last').attr('colspan','2').append($('<span>').text(' (lieu-dit)'))
        } else {
            $('#'+table+' tr:last').append($('<td>').addClass('zone-clic-adresses').append($('<span>'))
                                        .text('Relation')
                                        .click(function(){
                                            srcURL = 'http://127.0.0.1:8111/import?changeset_tags='+get_changeset_tags_addr(insee,nom_commune)+'&new_layer=true&layer_name='+nom_fantoir+'&url='+window.location.href.split('?')[0].replace(stringToRemove,'')+'requete_numeros.py?insee='+insee+'&fantoir='+fantoir+'&modele=Relation&fantoir_dans_relation='+fantoir_dans_relation;
                                            $('<img>').appendTo($('#josm_target')).attr('src',srcURL);
                                            $(this).addClass('clicked');
                                        })
                                    )
        }
    }
    function add_addr_inspector_link(table,insee,fantoir,source){
        $('#'+table+' tr:last').append($('<td>').addClass('zone-clic-adresses')
                                        .append($('<a>').attr('href',"numeros.html?insee="+insee+'&fantoir='+fantoir+'&source='+source+'&tab=0').attr('target',"blank")
                                        .text('Qualifier')
                                        )
                                        .click(function(){
                                            $(this).addClass('clicked');
                                        })
                                        )
    };
    function get_changeset_tags_addr(insee,nom_commune){
        return "source=https://bano.openstreetmap.fr/pifometre/index.html?insee="+insee+"%7Chashtags=%23BANO %23Pifometre%7Ccomment=Intégration d'adresses - "+nom_commune+" ("+insee+")"
    }
    function get_changeset_tags_noms(insee,nom_commune){
        return "source=https://bano.openstreetmap.fr/pifometre/index.html?insee="+insee+"%7Chashtags=%23BANO %23Pifometre%7Ccomment=Intégration de noms de voies et lieux-dits - "+nom_commune+" ("+insee+")"
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
            insee = fantoir.substr(0,5);
            statut = $(this)[0].value;
            $.ajax({
                url: "statut_fantoir.py?insee="+insee+"&fantoir="+fantoir+"&statut="+statut
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
        console.log('interactions_souris')
        if (couche_carto == 'BAN_point'||couche_carto == 'OSM_point'){
            //--------------------------------------------------
            //-------- AU SURVOL D'UN POINT D'ADRESSE  ---------
            //--------------------------------------------------
            map.on('mouseenter', couche_carto, (e) => {
                // Changer le curseur
                map.getCanvas().style.cursor = 'pointer';

                const coordinates = e.features[0].geometry.coordinates.slice();
                nom = e.features[0].properties.nom;
                map.setFilter('filaire',["==",["get", "nom"], nom])
                map.setFilter('filaire_texte',["==",["get", "nom"], nom])
                map.setFilter('hover_adresses_point',["==",["get", "nom"], nom])

                // Si la carte est dézoomée et que de multiples copies de la cible sont visibles, la pop-up apparaît sur la copie pointée
                while (Math.abs(e.lngLat.lng - coordinates[0]) > 180) {
                    coordinates[0] += e.lngLat.lng > coordinates[0] ? 360 : -360;
                }

                // Remplir la popup et définir ses coordonnées
                // popup.setLngLat(coordinates).setHTML(nom).addTo(map);
            });

            map.on('mouseleave', couche_carto, () => {
                map.getCanvas().style.cursor = '';
                // popup.remove();
                map.setFilter('filaire',["==",["get", "nom"], " "])
                map.setFilter('filaire_texte',["==",["get", "nom"], " "])
                map.setFilter('hover_adresses_point',["==",["get", "nom"], " "])
            });

            //-------------------------------------------------------
            //------------ AU CLIC SUR UN POINT D'ADRESSE -----------
            //-------------------------------------------------------
            map.on('click', couche_carto, (e) => {
                nom = e.features[0].properties.nom;
                fantoir = e.features[0].properties.fantoir;
                insee = fantoir.substring(0,5)
                numero = e.features[0].properties.numero;
                source = e.features[0].properties.source;
                rapproche = e.features[0].properties.rapproche;

                reset_panneau_map()
                $('#panneau_map h2').text(numero+' '+nom)

                $.ajax({
                    url: "requete_pifometre_voies.py?insee="+insee+'&fantoir='+fantoir
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

                        //Infos vois ou lieu-dit
                        $('#infos_voie_lieudit').append($('<p>').text('Code Fantoir : '+fantoir_affiche));
                        if (rapproche) {
                            $('#infos_voie_lieudit').append($('<p>')
                                                        .append($('<span class="pastille-verte" title="Déjà rapproché dans OSM">'))
                                                        .append($('<span>')
                                                            .text('Voie ou lieu-dit rapproché dans OSM')
                                                        )
                                                    );
                        }
                        else {
                            $('#infos_voie_lieudit').append($('<p>')
                                                        .append($('<span class="pastille-orange" title="Pas encore rapproché dans OSM">'))
                                                        .append($('<span>')
                                                            .text('Voie ou lieu-dit pas encore rapproché dans OSM')
                                                        )
                                                    );
                        }

                        //Infos numéro
                        // $('#infos_numero').append($('<h3>').text('Point d\'adresse'));
                        // $('#infos_numero').append($('<p>').text('Numéro : '+numero));
                        $('#infos_numero').append($('<p>').text('Source : '+source));

                        $('#infos_numero').append($('<p>').text('Voir sur : ').append($('<a>')
                                                            .attr('href',url_map_org_part1+'?mlat='+e.lngLat.lat+'&mlon='+e.lngLat.lng+'#map='+'18/'+e.lngLat.lat+'/'+e.lngLat.lng)
                                                            .attr('target','blank')
                                                            .text('ORG')));
                        xmin  = lon-DELTA
                        xmax  = lon+DELTA
                        ymin  = lat-DELTA
                        ymax  = lat+DELTA
                        table = 'table_liens'
                        $('#table_liens').append($('<tr>').append($('<td>').attr('colspan','2').text('Editer la zone')))
                        $('#table_liens').append('<tr>')
                        add_josm_link(table,xmin,xmax,ymin,ymax,insee,'nom_commune')
                        add_id_link(table,'http://www.openstreetmap.org/edit?editor=id#map=18/'+lat+'/'+lon,'ID')
                        $('#table_liens').append($('<tr>').append($('<td>').attr('colspan','2').text('Intégrer les adresses')))
                        $('#table_liens').append('<tr>')
                        add_josm_addr_link(table,insee,'nom_commune',fantoir,nom_topo,numeros_a_proposer,fantoir_dans_relation,is_place)
                        $('#table_liens').append('<tr>')
                        add_addr_inspector_link(table,insee,fantoir,'BAN')
                })
            });
        }
    }
    function reset_url_hash(){
        console.log('reset_url_hash')
        history.replaceState("", "", window.location.pathname+"?"+window.location.search)
    }
    function reset_panneau_map(){
        $('#panneau_map h2').empty()
        $('#infos_voie_lieudit').empty();
        $('#infos_numero').empty();
        $('#liens_voie').empty();
        $('#table_liens').empty();
    }
    function empty_layers(){
        map.getSource('points_nommes').setData(EMPTY_GEOJSON)
        map.getSource('contour_communal').setData(EMPTY_GEOJSON)
        map.getSource('hover_filaire').setData(EMPTY_GEOJSON)
        map.getSource('polygones_convexhull').setData(EMPTY_GEOJSON)
        map.getSource('adresses').setData(EMPTY_GEOJSON)
        map.getSource('hover').setData(EMPTY_GEOJSON)
    }
