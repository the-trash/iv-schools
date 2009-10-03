class AnsweresController < ApplicationController
  # GET /answeres
  # GET /answeres.xml
  def index
    @answeres = Answere.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @answeres }
    end
  end

  # GET /answeres/1
  # GET /answeres/1.xml
  def show
    @answere = Answere.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @answere }
    end
  end

  # GET /answeres/new
  # GET /answeres/new.xml
  def new
    @answere = Answere.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @answere }
    end
  end

  # GET /answeres/1/edit
  def edit
    @answere = Answere.find(params[:id])
  end

  # POST /answeres
  # POST /answeres.xml
  def create
    @answere = Answere.new(params[:answere])

    respond_to do |format|
      if @answere.save
        flash[:notice] = 'Answere was successfully created.'
        format.html { redirect_to(@answere) }
        format.xml  { render :xml => @answere, :status => :created, :location => @answere }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @answere.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /answeres/1
  # PUT /answeres/1.xml
  def update
    @answere = Answere.find(params[:id])

    respond_to do |format|
      if @answere.update_attributes(params[:answere])
        flash[:notice] = 'Answere was successfully updated.'
        format.html { redirect_to(@answere) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @answere.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /answeres/1
  # DELETE /answeres/1.xml
  def destroy
    @answere = Answere.find(params[:id])
    @answere.destroy

    respond_to do |format|
      format.html { redirect_to(answeres_url) }
      format.xml  { head :ok }
    end
  end
end
