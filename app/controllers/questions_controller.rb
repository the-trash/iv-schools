class QuestionsController < ApplicationController
  def index
    @question= @user.questions.new
  end
  
  def create
    # Найти по переданному zip коду пользователя самого пользователя получателя
    adresser_user= User.find_by_zip(params[:captcher_code])
    unless adresser_user
      # Если адресан не определен, то обработать ошибку хотя бы так
      render :text=>'Error Code #2148121009' and return
    end
    
    # Создать вопрос для данного пользователя    
    @question= adresser_user.questions.new(params[:question])
    
    # Если удалось сохранить (прошло валидацию)
    respond_to do |format|
      if @question.save
        flash[:notice] = 'Ваш вопрос успешно оправлен'
        format.html { redirect_to(questions_path) }
      else
        format.html { render :action => "index" }
      end#if
    end#respond_to do |format|
  end#create
end
