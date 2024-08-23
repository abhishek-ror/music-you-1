module BxBlockFreecreditsFreeCreditBalances

end

ActiveAdmin.register BxBlockFreecredits::FreecreditBalance, as: 'Freecredit' do
  menu false
  permit_params do
    permitted = [:amount, :gain_rate, :spend_rate, :max_gain_limit, :max_spend_limit]
    permitted << :other if params[:action] == 'create' && current_user.admin?
    permitted
  end
end
