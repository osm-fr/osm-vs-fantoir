/*---------------------MENU PRINCIPAL---------------------*/
let bouton_burger = document.querySelector('.controle_nav');
let bouton_burger_texte = document.querySelector('.bouton_burger span');
let bouton_burger_croix = document.querySelector('.bouton_burger');
let main_menu = document.querySelector('nav.navigation');

document.onclick = function(e){

    if (!main_menu.contains(e.target)   && !bouton_burger.contains(e.target) 
                                        && !bouton_burger_texte.contains(e.target) && !bouton_burger_croix.contains(e.target)) {
        $( ".controle_nav" ).prop( "checked", false );
    }
}