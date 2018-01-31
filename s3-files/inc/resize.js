var clicked = false;
function toggle() {
	if (clicked) {
		document.getElementById('asset').style.maxWidth = "95vw";
		document.getElementById('asset').style.maxHeight = "95vh";
		document.getElementById('asset').style.cursor = "zoom-in";
		clicked = false;
	}
	else {
		document.getElementById('asset').style.maxWidth = "100%";
		document.getElementById('asset').style.maxHeight = "100%";
		document.getElementById('asset').style.cursor = "zoom-out";
		clicked = true;
	}
}
