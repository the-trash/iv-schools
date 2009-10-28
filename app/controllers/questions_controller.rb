class QuestionsController < ApplicationController
  def index
    @question= @user.questions.new
    @questions = Question.paginate_all_by_user_id_and_state(@user.id, 'publicated',
                                                  :order=>"created_at DESC", #ASC, DESC
                                                  :page => params[:page],
                                                  :per_page=>3
                                                  )
  end
  
  def box
    @question= @user.questions.new
    @questions = Question.paginate_all_by_user_id_and_state(@user.id, ['new_question','seen', 'publicated'],
                                                  :order=>"created_at DESC", #ASC, DESC
                                                  :page => params[:page],
                                                  :per_page=>6
                                                  )
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
      if @question.save_with_captcha
        flash[:notice] = 'Ваш вопрос успешно оправлен'
        format.html { redirect_to(questions_path) }
      else
        # Если все данные валидны и не валидна только капча
        if @question.valid? && !@question.valid_with_captcha?
          flash[:notice] = 'Ошибка при вводе защитного кода'
        end
        format.html { render :action => "index" }
      end#if
    end#respond_to do |format|
  end#create
  
  def edit
    @question= Question.find_by_zip(params[:id])
    @question.reading if @question.can_reading?
  end#edit
  
  def update
    @question= Question.find_by_zip(params[:id])
    respond_to do |format|  
      if @question.update_attributes(params[:question])
        flash[:notice] = 'Вопрос изменен'
        format.html { redirect_back_or(questions_path) }
      else
        format.html { render :action => "edit" }
      end
    end
  end
  
  # Физического удаления не происходит,
  # просто вопрос получает состояние - удален (deleted)
  def destroy
    @question= Question.find_by_zip(params[:id])
    @question.deleting
    redirect_back_or(question_url(:subdomain=>@user.subdomain))
  end
  
  def publication
    @question= Question.find_by_zip(params[:id])
    @question.publication
    redirect_to(box_questions_url(:subdomain=>@user.subdomain))
  end
  
  def unpublication
    @question= Question.find_by_zip(params[:id])
    @question.unpublication
    redirect_to(box_questions_url(:subdomain=>@user.subdomain))
  end

  # Физическое удаление вопроса из БД - только для администратора
  def physic_delete
    @question= Question.find_by_zip(params[:id])
    @question.destroy
    redirect_back_or(question_url(:subdomain=>@user.subdomain))
  end
end
