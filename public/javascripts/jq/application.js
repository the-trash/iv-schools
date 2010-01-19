function show_editor_block(){
  $('#current_editor_bar').hide("blind", { direction: "vertical" }, 500);
  $('#current_editor_block').delay(600).show("blind", { direction: "vertical" }, 700);
}
function hide_editor_block(){
  $('#current_editor_block').hide("blind", { direction: "vertical" }, 700);
  $('#current_editor_bar').delay(800).show("blind", { direction: "vertical" }, 500);
}
function show_add_file_form(){  
  $('#add_file_link').hide();
  $('#add_file_form').show("blind", { direction: "vertical" }, 500);
}
function show_question_form(){
    $('#question_shower').hide("blind", { direction: "vertical" }, 300);
    $('#question_block').delay(400).show("blind", { direction: "vertical" }, 500);
}
function hide_question_form(){
    $('#question_block').hide("blind", { direction: "vertical" }, 500);
    $('#question_shower').delay(600).show("blind", { direction: "vertical" }, 500);
}
    