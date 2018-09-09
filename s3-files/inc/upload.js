function addPhoto() {
	var files = document.getElementById('photoupload').files;
	if (!files.length) {
		return alert('Please choose a file to upload first.');
	}
	var file = files[0];
	var fileName = file.name;
	var prefix = 'assets//';

	var imageKey = albumPhotosKey + fileName;
	s3.upload({
		Key: imageKey,
		Body: file,
		ACL: 'public-read'
	}, function(err, data) {
		if (err) {
			return alert('There was an error uploading your image: ', err.message);
		}
		alert('Successfully uploaded image.');
	});
}
