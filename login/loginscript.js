var pwd = "@TH220th220@";
function passcheck(){
if (document.getElementById('password').value != pwd){
	alert('Oops, Wrong Password, Try Again Please.');
	document.getElementById("login-form").reset();
	return false;
}	
if (document.getElementById('password').value == pwd){
}
};

function clearform() {
  document.getElementById("login-form").reset();
}
