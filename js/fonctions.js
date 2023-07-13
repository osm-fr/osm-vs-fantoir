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
            if (window.location.hash.split('insee=')[1]){
                if (pattern_insee.test(window.location.hash.split('insee=')[1].split('&')[0])){
                    res = window.location.hash.split('insee=')[1].split('&')[0]
                } else {
                    alert(window.location.hash.split('insee=')[1].split('&')[0]+' n\'est pas un code INSEE de commune\n\nAbandon')
                }
            }
        }
        return res
    }
