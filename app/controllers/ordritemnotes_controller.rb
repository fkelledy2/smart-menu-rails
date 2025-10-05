class OrdritemnotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_ordritemnote, only: %i[show edit update destroy]
  
  # Pundit authorization
  after_action :verify_authorized, except: [:index]
  after_action :verify_policy_scoped, only: [:index]

  # GET /ordritemnotes or /ordritemnotes.json
  def index
    @ordritemnotes = policy_scope(Ordritemnote)
  end

  # GET /ordritemnotes/1 or /ordritemnotes/1.json
  def show
    authorize @ordritemnote
  end

  # GET /ordritemnotes/new
  def new
    @ordritemnote = Ordritemnote.new
    authorize @ordritemnote
  end

  # GET /ordritemnotes/1/edit
  def edit
    authorize @ordritemnote
  end

  # POST /ordritemnotes or /ordritemnotes.json
  def create
    @ordritemnote = Ordritemnote.new(ordritemnote_params)
    authorize @ordritemnote
    
    respond_to do |format|
      if @ordritemnote.save
        format.html do
          redirect_to ordritemnote_url(@ordritemnote), 
                      notice: t('common.flash.created', resource: t('activerecord.models.ordritemnote'))
        end
        format.json { render :show, status: :created, location: @ordritemnote }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @ordritemnote.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ordritemnotes/1 or /ordritemnotes/1.json
  def update
    authorize @ordritemnote
    
    respond_to do |format|
      if @ordritemnote.update(ordritemnote_params)
        format.html do
          redirect_to ordritemnote_url(@ordritemnote), 
                      notice: t('common.flash.updated', resource: t('activerecord.models.ordritemnote'))
        end
        format.json { render :show, status: :ok, location: @ordritemnote }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @ordritemnote.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ordritemnotes/1 or /ordritemnotes/1.json
  def destroy
    authorize @ordritemnote
    
    @ordritemnote.destroy!
    respond_to do |format|
      format.html do
        redirect_to ordritemnotes_url, 
                    notice: t('common.flash.deleted', resource: t('activerecord.models.ordritemnote'))
      end
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_ordritemnote
    @ordritemnote = Ordritemnote.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def ordritemnote_params
    params.require(:ordritemnote).permit(:note, :ordritem_id)
  end
end
