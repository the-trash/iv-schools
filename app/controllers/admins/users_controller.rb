class Admins::UsersController < ApplicationController
  layout 'admin_application.haml'
  
  # GET /users
  def index
    @users = User.paginate(:all,
                           :order=>"created_at ASC", #ASC, DESC
                           :page => params[:page],
                           :per_page=>6
                           )
                           
    respond_to do |format|
      format.html # index.haml
    end
  end

  # GET /users/1
  def show
    @user = User.find(params[:id])

    respond_to do |format|
      format.html # show.haml
    end
  end

  # GET /users/new
  def new
    @user = User.new

    respond_to do |format|
      format.html # new.haml
    end
  end

  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
  end

  # POST /users
  def create
    @user = User.new(params[:user])

    respond_to do |format|
      if @user.save
        flash[:notice] = 'user успешно создано.'
        format.html { redirect_to(admins_user_path(@user)) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /users/1
  def update
    @user = User.find(params[:id])

    respond_to do |format|
      if @user.update_attributes(params[:user])
        flash[:notice] = 'user успешно обновлено.'
        format.html { redirect_to(edit_admins_user_path(@user)) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /users/1
  def destroy
    @user = User.find(params[:id])
    @user.destroy

    respond_to do |format|
      format.html { redirect_to(admins_users_url) }
    end
  end
  
  def change_role
    @user = User.find(params[:id])
    @user.role_id= params[:user][:role_id]
    @user.save!
    redirect_back_or ('/')
  end
  
end