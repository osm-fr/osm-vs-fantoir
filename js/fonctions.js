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
                if (is_valid_dept(window.location.hash.split('dept=')[1].split('&')[0])){
                    res = window.location.hash.split('dept=')[1].split('&')[0]
                } else {
                    alert(window.location.hash.split('dept=')[1].split('&')[0]+' n\'est pas un numero de département valide\n\nAbandon')
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
    function check_url_for_insee(){
        pattern_insee = new RegExp('^[0-9][0-9abAB][0-9]{3}$')
        var res
        if (window.location.hash){
            if (window.location.hash.split('insee=')[1].split('&')[0]){
                if (pattern_insee.test(window.location.hash.split('insee=')[1].split('&')[0])){
                    res = window.location.hash.split('insee=')[1].split('&')[0]
                } else {
                    alert(window.location.hash.split('insee=')[1].split('&')[0]+' n\'est pas un code INSEE de commune\n\nAbandon')
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
    function add_josm_link(table,xl,xr,yb,yt){
        $('#'+table+' tr:last').append($('<td>').addClass('zone-clic-josm')
                                    .attr('xleft',xl).attr('xright',xr).attr('ybottom',yb).attr('ytop',yt)
                                    .text('JOSM')
                                    .click(function(){
                                        srcLoadAndZoom = 'http://127.0.0.1:8111/load_and_zoom?left='+xl+'&right='+xr+'&top='+yt+'&bottom='+yb;
                                        $('<img>').appendTo($('#josm_target')).attr('src',srcLoadAndZoom);
                                        $(this).addClass('clicked');
                                    })
                                )
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
