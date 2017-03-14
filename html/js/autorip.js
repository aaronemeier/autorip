/*
 * JavaScripts created for AutoRip
 * Author: Aaron Meier <aaron@bluespeed.org>
 */
$(document).ready(function(){
    if(checkState()){
        $('#state').html('<div class="alert alert-info" role="alert"> \
                          <strong>Still running..</strong> \
                          Converting is still in progress. Please wait.</div>');
        writeLog("main");
        setInterval(function(){
            if(location.hash == ''){
                if(checkState()){
                    writeLog("main");
                }else{
                    location.reload();
                }
            }
        }, 10000);
    }else{
        $('#state').html('<div class="alert alert-success" role="alert">\
                          <strong>Successfully ripped!</strong> \
                          File has been saved. Insert a new volume.</div>');
        $('#joblog1').html('<p>Nothing to do.</p>');
    }
	$('ul li a').click(function(){
	    $('.nav').children('li').each(function(){
            $(this).removeClass('active');
        });
        $(this).parent('li').addClass('active');
	    checkURL(this.hash);
	});
});

function writeLog(type){
    if(type == "video"){
        $('#logs').html('<div class="page-header"> \
                            <h3>DVD Log</h3> \
                        </div> \
                        <div class="well" id="joblog1"></div> \
                        <div class="page-header"> \
                            <h3>Blu-Ray Log</h3> \
                        </div> \
                        <div class="well" id="joblog2"></div>')
        $.ajax({
            url: '/logs/dvd.txt',
            type: 'GET',
            cache: false,
            dataType: 'text',
            success: function(data){
                    if(data.trim() == ''){
                        $('#joblog1').html('<p>Log is empty. Sorry. </p>');
                    }else{
                        $('#joblog1').html(data.replace(/(?:\r\n|\r|\n)/g, '<br />'));
                    }
            }
        });
        $.ajax({
            url: '/logs/bluray.txt',
            type: 'GET',
            cache: false,
            dataType: 'text',
            success: function(data){
                    if(data.trim() == ''){
                        $('#joblog2').html('<p>Log empty. Sorry. </p>');
                    }else{
                        $('#joblog2').html(data.replace(/(?:\r\n|\r|\n)/g, '<br />'));
                    }
            }
        });
    }else{
        $.ajax({
            url: '/logs/' + type + '.txt',
            type: 'GET',
            cache: false,
            dataType: 'text',
            success: function(data){
                    if(data.trim() == ''){
                        $('#joblog1').html('<p>Log is empty. Sorry. </p>');
                    }else{
                        if(type == 'main'){
                            data = changeText(data);
                            $('#joblog1').html(data.replace(/(?:\r\n|\r|\n)/g, '<br />'));
                            $("#joblog1").dotdotdot({
                                ellipsis: '',
                                wrap: 'word',
                                fallbackToLetter: false,
                                height: 1000,
                                tolerance: 0
                            });
                        }else{
                            $('#joblog1').html(data.replace(/(?:\r\n|\r|\n)/g, '<br />'));
                        }
                    }
            }
        });
    }
}

function changeText(content){
    var lines = content.split('\n');
    var result = '';
    for(var i=0; i < lines.length; i++){
        result = lines[i] + "\n" + result;
    }
    return result;
}

function checkURL(hash){
    $('#logs').html('<div class="well" id="joblog1"></div>')
    switch(hash){
        case "#audiolog":
            $('#title').html('<h1>Audio Log</h1>');
            writeLog("audio");
            break;
        case "#videolog":
            $('#title').html('<h1>Video Log</h1>');
            writeLog("video");
            break;
        default:
            $('#title').html('<h1>Running Jobs</h1>');
            if(checkState()){
                writeLog("main");
                $('#state').html('<div class="alert alert-info" role="alert"> \
                                  <strong>Still running..</strong> \
                                  Converting is still in progress. Please wait.</div>');

            }else{
                $('#joblog1').html('<p>Nothing to do.</p>');
                $('#state').html('<div class="alert alert-success" role="alert">\
                                  <strong>Successfully ripped!</strong> \
                                  File has been saved. Insert a new volume.</div>');
            }
            break;
    }
}

function checkState(){
    var result = false;
    $.ajax({
		url: '/logs/state.txt',
		type: 'GET',
		cache: false,
		dataType: 'text',
		async: false,
		success: function(data){
		    if(data == 1){
		        result = true;
		    }
	    }
	});
	return result;
}
