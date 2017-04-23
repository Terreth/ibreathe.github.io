"use strict";

var currAccount;
var Web3;
var web3;
var gasAmount;
var gasPrice;
var token;
var mongoDBURL = "http://127.0.0.1:8085/";


function init() {
   
	var proposal,
		mode,
		newProposalInput,
		newRegistration,
		newProposalButton,
		loginButton,
		newRegistrationButton,
		rulesChangeButton,
		investButton;
    

	currAccount = getCookie("account");

   
    $("#title-brand").text(organizationName);
    $("#page-title").text(organizationName);
    $("#logo-title-link").html('<a href="http://'+ domain +'" class="simple-text">'+ organizationName +' </a>');
    $("#logo-mini-link").html('<a href="http://'+ domain +'" class="simple-text">'+ organizationName +' </a>');

 
	

   // mode = decodeURI(getParameterByName('mode'));
    //document.getElementById('proposal').textContent = proposal;

    if (getCookie("emailAddress") != "" ) {		
        //$("#menu-signup").html( "<span class='glyphicon glyphicon-user'></span> " + getCookie("firstName") + " " + getCookie("lastName") );
        $("#user-drop-down").prepend(getCookie("firstName") + " " + getCookie("lastName") );
        
        $("#menu-signup").hide();
        $("#menu-login").hide();        
        $("#menu-signup").css("background-color", "lightgreen");
    }
    
    /*
    if (addr.length === 42 && addr.includes("0x", 0)) {
		logedIn = true;
		enableMenuAll();
	} */

   



    
    // Checks Web3 support
    if (typeof web3 !== 'undefined' && typeof Web3 !== 'undefined') {
        // If there's a web3 library loaded, then make your own web3
        web3 = new Web3(web3.currentProvider);
    } else if (typeof Web3 !== 'undefined') {
        // If there isn't then set a provider
		//var Method = require('./web3/methods/personal');
        web3 = new Web3(new Web3.providers.HttpProvider(connectionString));

        if (!web3.isConnected()){

            $("#alert-danger-span").text(" Problem with connection to the newtwork. Please contact " + supportEmail + " abut it. ");  
            $("#alert-danger").show();
            return; 
        }
    } else if (typeof web3 == 'undefined' && typeof Web3 == 'undefined') {

        Web3 = require('web3');
        web3 = new Web3();
		web3.setProvider(new web3.providers.HttpProvider(onnectionString));
    }
 	

	gasPrice = web3.eth.gasPrice;
	gasAmount = 4000000;

    var etherTokenContract = web3.eth.contract(toeknContractABI);
    token = etherTokenContract.at(tokenContractAddress);

    

   
    

}

function getCookie(cname) {
	
    var name = cname + "=", ca = document.cookie.split(';'), i, c;
	
    for (i = 0; i < ca.length; i += 1) {
        c = ca[i];
        while (c.charAt(0) === ' ') {
            c = c.substring(1);
        }
        if (c.indexOf(name) === 0) {
            return c.substring(name.length, c.length);
        }
    }
    return "";
}


// submit new investment proposal to mongodb




$(document).on('submit', '#register-form-initial', function (e) {
      e.isDefaultPrevented()
   
        $.post(mongoDBURL + "process_add_one",


            {
                blockchainAddress: $("input[name=addr]").val(),
                firstName: $("input[name=firstName]").val(),
                lastName: $("input[name=lastName]").val(),
                emailAddress: $("input[name=emailAddress]").val(),
                password: $("input[name=password]").val(),
                confirmPassword: $("input[name=confirmPassword]").val()              
            },
            function (data, status) {              

                if (data == "success" && status == "success") {
                    showTimeNotification('top','right', "An acoount created.")
                }
                else {
                    showTimeNotification('top','right', "Creation of an acoount failed.")
                }
            });
    });


    function showTimeNotification(from, align, text) {

    var type = ['', 'info', 'success', 'warning', 'danger', 'rose', 'primary'];

    var color = Math.floor((Math.random() * 6) + 1);

    $.notify({
        icon: "notifications",
        message: text

    }, {
            type: type[color],
            timer: 30000,
            z_index: 10031,
            placement: {
                from: from,
                align: align
            }
        });
}

function setFormValidation(id) {
    $(id).validate({
        errorPlacement: function (error, element) {
            $(element).parent('div').addClass('has-error');
        }
    });
}

$(document).ready(function () {

setFormValidation('#register-form-initial');

});