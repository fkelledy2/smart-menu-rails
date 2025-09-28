class TestimonialsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_testimonial, only: %i[show edit update destroy]

  # Pundit authorization
  after_action :verify_authorized, except: [:index]
  after_action :verify_policy_scoped, only: [:index]

  # GET /testimonials or /testimonials.json
  def index
    @testimonials = policy_scope(Testimonial)
  end

  # GET /testimonials/1 or /testimonials/1.json
  def show
    authorize @testimonial
  end

  # GET /testimonials/new
  def new
    @testimonial = Testimonial.new
    authorize @testimonial
  end

  # GET /testimonials/1/edit
  def edit
    authorize @testimonial
  end

  # POST /testimonials or /testimonials.json
  def create
    @testimonial = Testimonial.new(testimonial_params)
    authorize @testimonial

    respond_to do |format|
      if @testimonial.save
        format.html do
          redirect_to @testimonial, notice: t('common.flash.created', resource: t('activerecord.models.testimonial'))
        end
        format.json { render :show, status: :created, location: @testimonial }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @testimonial.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /testimonials/1 or /testimonials/1.json
  def update
    respond_to do |format|
      if @testimonial.update(testimonial_params)
        format.html do
          redirect_to @testimonial, notice: t('common.flash.updated', resource: t('activerecord.models.testimonial'))
        end
        format.json { render :show, status: :ok, location: @testimonial }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @testimonial.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /testimonials/1 or /testimonials/1.json
  def destroy
    @testimonial.destroy!

    respond_to do |format|
      format.html do
        redirect_to testimonials_path, status: :see_other,
                                       notice: t('common.flash.deleted', resource: t('activerecord.models.testimonial'))
      end
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_testimonial
    @testimonial = Testimonial.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def testimonial_params
    params.require(:testimonial).permit(:testimonial, :sequence, :status, :user_id, :restaurant_id)
  end
end
