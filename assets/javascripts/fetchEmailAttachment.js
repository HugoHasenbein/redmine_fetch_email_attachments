function fetchJsForm(url, form, attachmentId) {
  var attId = {attachment_id: attachmentId};
  if(form.value=='') 
  	return;
  $.ajax({
    url: url,
    type: 'post',
    data: $(form).serialize() + '&attachment_id=' + attachmentId.toString()
  });
}
