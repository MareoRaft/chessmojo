var ws

if ("WebSocket" in window) { ws = new WebSocket('<%= url_for('chesssocket')->to_abs %>') }
if(typeof(ws) !== 'undefined') {
	function sendID (evt) {
		x = evt.currentTarget.getAttribute('x')
		y = evt.currentTarget.getAttribute('y')
		ws.send( JSON.stringify({'command': 'squareclicked', 'x': x, 'y': y}) )
		document.getElementById('container').innerHTML += "<br />"
		%#document.getElementById('container').innerHTML += "id is "+ID+"<br />"
		document.getElementById('container').innerHTML += "target is "+evt.target+"<br />"
		document.getElementById('container').innerHTML += "currentTarget is "+evt.currentTarget+"<br />"
		document.getElementById('container').innerHTML += "x is "+evt.currentTarget.getAttribute('x')+"<br />"
		document.getElementById('container').innerHTML += "y is "+evt.currentTarget.getAttribute('y')+"<br />"
	}
	function sendmessage (evt,message) {
			ws.send(JSON.stringify({'command': 'donothing', 'message': message}))
	}
	ws.onmessage = function (event) {

		var json = JSON.parse(event.data)

		document.getElementById('container').innerHTML += ' Command is "'+json.command+'".'
		%#for (i=0; i<json.options.length; ++i){
		%#	document.getElementById('container').innerHTML += ' options['+i+'] is "'+json.options[i]+'".'
		%#}

		%# with this method, whenever i send the lastclickedoptions, therefore i want to erase them
		if( typeof(json.lastclickedoptions) !== 'undefined' ){
			for (i=0; i<json.lastclickedoptions.length; ++i){
				%# double quotes necessary
				document.getElementById(json.lastclickedoptions[i]).removeAttribute('style')
				%#document.getElementById(json.lastclickedoptions[i]).setAttribute('fill',"yellow")
			}
		}
		if( json.command=='fillsquares' ){
			for (i=0; i<json.options.length; ++i){
				%# double quotes necessary
				document.getElementById(json.options[i]).setAttribute('style',"opacity:0.5")
			}
		}

		if( json.command=='movepiece' ){
			%#alert('moving piece')
			document.getElementById(json.ID).setAttribute('x',json.x)
			document.getElementById(json.ID).setAttribute('y',json.y)
		}
		if( typeof(json.IDtoremove) !== 'undefined' ){
			document.getElementById(json.IDtoremove).setAttribute('x',-1)
			document.getElementById(json.IDtoremove).setAttribute('y',-1)
		}


	}
	ws.onopen = function (event) {
		document.getElementById('container').innerHTML += ' onopen. '
		sendmessage(event,'WebSocket support works! ♥')
	}
}
else {
	document.body.innerHTML += 'Browser does not support WebSockets.'
}

window.onresize = function(){
	document.getElementById('left').setAttribute('style',"float:left; background:yellow; width:"+Math.min(window.innerWidth,window.innerHeight)*0.6+"px; height:100%")
}
