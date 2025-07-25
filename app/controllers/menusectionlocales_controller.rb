class MenusectionlocalesController < ApplicationController
  before_action :set_menusectionlocale, only: %i[show edit update destroy]

  def index
    @menusectionlocales = Menusectionlocale.limit(100) # Use limit for memory safety, since pagination gem is not installed
  end

  def show
  end

  def new
    @menusectionlocale = Menusectionlocale.new
  end

  def create
    @menusectionlocale = Menusectionlocale.new(menusectionlocale_params)
    if @menusectionlocale.save
      redirect_to menusectionlocale_url(@menusectionlocale), notice: 'Menusectionlocale was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @menusectionlocale.update(menusectionlocale_params)
      redirect_to menusectionlocale_url(@menusectionlocale), notice: 'Menusectionlocale was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @menusectionlocale.destroy
    redirect_to menusectionlocales_url, notice: 'Menusectionlocale was successfully destroyed.'
  end

  private
    def set_menusectionlocale
      @menusectionlocale = Menusectionlocale.find(params[:id])
    end

    def menusectionlocale_params
      params.require(:menusectionlocale).permit(:locale, :status, :name, :description, :menusection_id)
    end
end
