class OrdritemnotesController < ApplicationController
  before_action :set_ordritemnote, only: %i[show edit update destroy]

  # GET /ordritemnotes or /ordritemnotes.json
  def index
    if current_user
      @ordritemnotes = []
      Restaurant.where(user: current_user).find_each do |restaurant|
        Ordr.where(restaurant: restaurant).find_each do |ordr|
          Ordritem.where(ordr: ordr).find_each do |ordritem|
            @ordritemnotes += Ordritemnote.where(ordritem: ordritem).all
          end
        end
      end
    else
      redirect_to root_url
    end
  end

  # GET /ordritemnotes/1 or /ordritemnotes/1.json
  def show
    unless current_user
      redirect_to root_url
    end
  end

  # GET /ordritemnotes/new
  def new
    if current_user
      @ordritemnote = Ordritemnote.new
    else
      redirect_to root_url
    end
  end

  # GET /ordritemnotes/1/edit
  def edit
    unless current_user
      redirect_to root_url
    end
  end

  # POST /ordritemnotes or /ordritemnotes.json
  def create
    if current_user
      @ordritemnote = Ordritemnote.new(ordritemnote_params)
      respond_to do |format|
        if @ordritemnote.save
          format.html do
            redirect_to ordritemnote_url(@ordritemnote), notice: 'Ordritemnote was successfully created.'
          end
          format.json { render :show, status: :created, location: @ordritemnote }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @ordritemnote.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to root_url
    end
  end

  # PATCH/PUT /ordritemnotes/1 or /ordritemnotes/1.json
  def update
    if current_user
      respond_to do |format|
        if @ordritemnote.update(ordritemnote_params)
          format.html do
            redirect_to ordritemnote_url(@ordritemnote), notice: 'Ordritemnote was successfully updated.'
          end
          format.json { render :show, status: :ok, location: @ordritemnote }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @ordritemnote.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to root_url
    end
  end

  # DELETE /ordritemnotes/1 or /ordritemnotes/1.json
  def destroy
    if current_user
      @ordritemnote.destroy!
      respond_to do |format|
        format.html { redirect_to ordritemnotes_url, notice: 'Ordritemnote was successfully destroyed.' }
        format.json { head :no_content }
      end
    else
      redirect_to root_url
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_ordritemnote
    if current_user
      @ordritemnote = Ordritemnote.find(params[:id])
      if @ordritemnote.nil? || (@ordritemnote.ordr.restaurant.user != current_user)
        redirect_to root_url
      end
    else
      redirect_to root_url
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_url
  end

  # Only allow a list of trusted parameters through.
  def ordritemnote_params
    params.require(:ordritemnote).permit(:note, :ordritem_id)
  end
end
