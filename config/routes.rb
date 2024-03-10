Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions'
  }
  resources :financial_info, only: [:create, :update, :destroy]
  get 'financial_info/:id/results', to: 'financial_info#get_results'
end
