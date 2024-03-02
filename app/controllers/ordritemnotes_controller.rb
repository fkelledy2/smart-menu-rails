class OrdritemnotesController < ApplicationController
  before_action :set_ordritemnote, only: %i[ show edit update destroy ]

  # GET /ordritemnotes or /ordritemnotes.json
  def index
    @ordritemnotes = Ordritemnote.all
  end

  # GET /ordritemnotes/1 or /ordritemnotes/1.json
  def show
  end

  # GET /ordritemnotes/new
  def new
    @ordritemnote = Ordritemnote.new
  end

  # GET /ordritemnotes/1/edit
  def edit
  end

  # POST /ordritemnotes or /ordritemnotes.json
  def create
    @ordritemnote = Ordritemnote.new(ordritemnote_params)

    respond_to do |format|
      if @ordritemnote.save
        format.html { redirect_to ordritemnote_url(@ordritemnote), notice: "Ordritemnote was successfully created." }
        format.json { render :show, status: :created, location: @ordritemnote }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @ordritemnote.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ordritemnotes/1 or /ordritemnotes/1.json
  def update
    respond_to do |format|
      if @ordritemnote.update(ordritemnote_params)
        format.html { redirect_to ordritemnote_url(@ordritemnote), notice: "Ordritemnote was successfully updated." }
        format.json { render :show, status: :ok, location: @ordritemnote }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @ordritemnote.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ordritemnotes/1 or /ordritemnotes/1.json
  def destroy
    @ordritemnote.destroy!

    respond_to do |format|
      format.html { redirect_to ordritemnotes_url, notice: "Ordritemnote was successfully destroyed." }
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
