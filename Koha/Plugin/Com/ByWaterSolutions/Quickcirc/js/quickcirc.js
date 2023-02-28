$(document).ready(function(){
    $("#header_search ul").append('<li><a href="#" class="launch_quickcirc"><i class="fa fa-fw fa-bolt"></i>Quick circ</a></li>');
    $("body").on('click','.launch_quickcirc',function(){
        $("#qc_error").text('').hide();
        $("#qc_results_list").html('');
        $("#quickcirc_modal").modal({show:true});
    });

    $("body").on('submit',"#quickcirc_form",function(e){
        e.preventDefault();
        $("#qc_error").text('').hide();
        let qc_barcode = $("#quickcirc_form #qc_barcode").val();
        $.post('/api/v1/contrib/quickcirc/quickcirc',JSON.stringify({ "barcode": qc_barcode }))
        .success(function(data){
            $("#quickcirc_form #qc_barcode").val('');

            let qc_result = " Barcode " + qc_barcode + ": ";
            if( data.issue ){
                qc_result += ' <span class="qc_checkout">Checked out</span> To: ' + data.patron.firstname + " " + data.patron.surname + "(" + data.patron.cardnumber + ")";
                qc_result += ', Due: ' + data.issue.date_due;
            } else {
                qc_result += ' <span class="qc_return">Returned</span> ';
            }
            if( data.WrongTransfer || data.NeedsTransfer || data.WasTransferred ){
                qc_result += " Please transfer to " + ( data.WrongTransfer || data.NeedsTransfer || data.WasTransferred) + ". ";
            }
            if( data.WasLost ){
                qc_result += " Was lost, now marked found. ";
            }
            console.log( data );
            $("#qc_results_list").append('<li>' + qc_result + '</li>');
        })
        .error(function(data){
            if( data.status == '404' ){
                $("#qc_error").text('Barcode ' + qc_barcode + ' not found');
            } else {
                $("#qc_error").text("Error: please check item in to Koha");
            }
            $("#qc_error").show();
        });
    });
});
