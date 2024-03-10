class FinancialInfo < ApplicationRecord
    validates :flow_of_data, inclusion: { in: %w[vertical horizontal], message: "%{value} is not a valid flow of data" }
    
    after_update :convert_to_json

    def convert_to_json
        self.compute_formulas = compute_formulas.map do |compute_formula| 
            return compute_formula.to_json
        end    
    end
end
