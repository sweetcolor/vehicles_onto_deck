Rails.application.routes.draw do
  get '/:query', to: 'main_page#query'
  root to: 'main_page#index'
end
