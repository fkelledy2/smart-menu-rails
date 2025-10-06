class MenusectionlocalesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_menusectionlocale, only: %i[show edit update destroy]
  
  # Pundit authorization
  after_action :verify_authorized, except: [:index]
  after_action :verify_policy_scoped, only: [:index]

  def index
    if params[:menu_id]
      @menu = Menu.find(params[:menu_id])
      @menusectionlocales = policy_scope(Menusectionlocale).joins(:menusection)
        .where(menusections: { menu: @menu }).limit(100)
    else
      @menusectionlocales = policy_scope(Menusectionlocale).limit(100)
    end
  end

  def show
    authorize @menusectionlocale
  end

  def new
    @menusectionlocale = Menusectionlocale.new
    if params[:menu_id]
      @menu = Menu.find(params[:menu_id])
    end
    authorize @menusectionlocale
  end

  def edit
    authorize @menusectionlocale
  end

  def create
    @menusectionlocale = Menusectionlocale.new(menusectionlocale_params)
    authorize @menusectionlocale
    
    if @menusectionlocale.save
      redirect_to menusectionlocale_url(@menusectionlocale), 
                  notice: t('common.flash.created', resource: t('activerecord.models.menusectionlocale'))
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @menusectionlocale
    
    if @menusectionlocale.update(menusectionlocale_params)
      redirect_to menusectionlocale_url(@menusectionlocale), 
                  notice: t('common.flash.updated', resource: t('activerecord.models.menusectionlocale'))
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @menusectionlocale
    
    @menusectionlocale.destroy
    redirect_to menusectionlocales_url, 
                notice: t('common.flash.deleted', resource: t('activerecord.models.menusectionlocale'))
  end

  private

  def set_menusectionlocale
    @menusectionlocale = Menusectionlocale.find(params[:id])
  end

  def menusectionlocale_params
    params.require(:menusectionlocale).permit(:locale, :status, :name, :description, :menusection_id)
  end
end
