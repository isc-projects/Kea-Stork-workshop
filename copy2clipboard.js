function copy2clipboard(id) {
  buttonid = 'button'+id
  // submitted id MUST be a form field
  // buttonid must be the id of the button to be disabled and replaced with "copied!"
  // Find the element that contains the text to be copied
  let formElem = document.getElementById(id);
  console.log(formElem)
  // get the text and copy it to clipboard
  let text = formElem.innerText;
  navigator.clipboard.writeText(text);

  // disable button and set to "copied!" to let the user know that it was copied to clipboard
  // get original values (for use in a moment)
  let origHTML = document.getElementById(buttonid).innerHTML;
  let origCSS = document.getElementById(buttonid).style.color;
  // set new values
  document.getElementById(buttonid).innerHTML = '<b><font size=5px>&#x2398;</font></b> COPIED!'
  document.getElementById(buttonid).style.color = '#D3D3D3';
  // now wait a moment and then put back original values so user can continue to use the form
  setTimeout(() => {
    document.getElementById(buttonid).innerHTML = origHTML;
    document.getElementById(buttonid).style.color = origCSS;
  }, 5000);
}

