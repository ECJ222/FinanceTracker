require 'dentaku'

class FinancialInfoController < ApplicationController
  before_action :authenticate_user!

  @@calculator = Dentaku::Calculator.new
  
  def create
    uploaded_file = params[:data_source]
    file_extension = File.extname(uploaded_file.original_filename) if uploaded_file.present?

    if file_extension != ".csv"
      render json: { message: "Invalid file format. Please upload a CSV file" }
      return
    end

    financial_info = FinancialInfo.new(financial_info_params)
    financial_info[:data_source] = File.read(uploaded_file)
    
    if financial_info.save
      render json: { message: "Financial Information successfully created", financial_info: financial_info }
    else
      render json: { message: "Financial Information not created", errors: financial_info.errors.full_messages }
    end
  end

  def update
    financial_info = FinancialInfo.where(id: params[:id], user_id: current_user.id)

    if financial_info.empty?
      render json: { message: "Financial Info not found" }, :status => :not_found
      return
    end

    has_valid_compute_formulas = financial_info_params[:compute_formulas].all? {
      |compute_formula| is_compute_formula_valid(compute_formula[:value])
    }

    if !has_valid_compute_formulas
      render json: { message: "Invalid compute formula" }
      return
    end

    if financial_info.update(financial_info_params)
      render json: { message: "Financial Info has been updated successfully", financial_info: financial_info }
    else
      render json: { message: "Financial Info could not be updated", errors: financial_info.errors.full_messages }
    end
  end


  def is_compute_formula_valid(compute_formula)
    num_only_pattern = /(row\(\d+\)col\(\d+\))(?: ?\+|-|\*|\/ ?row\(\d+\)col\(\d+\))*/
    # add more patterns as needed
    return num_only_pattern.match(compute_formula)
  end

  def get_results
    financial_info = FinancialInfo.where(id: params[:id], user_id: current_user.id)

    if financial_info.empty?
      render json: { message: "Financial Info not found" }, :status => :not_found
      return
    end

    formatted_data = get_data(financial_info[0][:data_source], financial_info[0][:flow_of_data])

    if formatted_data[:legends].length == 0 || formatted_data[:values].length == 0 
      render json: { message: "Financial Information is empty" }
      return
    end

    formatted_data[:chart_data] = get_chart_data(formatted_data[:values])
    formatted_data[:computed_data] = get_computed_data(formatted_data[:values], financial_info[0][:compute_formulas])
    formatted_data.delete(:values)

    render json: { message: "Financial Information successfully retrieved", financial_info: formatted_data }
  rescue => e
    render json: { message: "An error occurred while computing the data", errors: e.message }
  end

  def get_data(finance_data, flow_of_data = "vertical")
    data = finance_data.split(/\r?\n/)
    legends = get_legends(data, flow_of_data)
    values = get_values(data, flow_of_data)

    return { legends: legends, chart_data: [], values: values }
  end

  def get_legends(data, flow_of_data)
    if flow_of_data == 'vertical'
      return data[0].split(",")
    elsif flow_of_data == 'horizontal'
      return data.map { |row| row.split(",")[0] }
    end
  end

  def get_values(data, flow_of_data)
    if flow_of_data == 'vertical'
        data[1..-1].map do |row| 
          row = row.gsub(/[^\w\s,\.]/, "")
          row.split(",")
        end
    elsif flow_of_data == 'horizontal'
      data[1..-1].map{|row| row.gsub(/[^\w\s,\.]/, "").split(",")[1..-1]}
    end
  end

  def get_chart_data (values)
    data = values[0].map(&:to_i)
    for i in 1...values.length
      data = data.zip(values[i]).map{|a, b| a.to_f + b.to_f}
    end
    return data
  end

  def get_computed_data (data, compute_formulas)
    compute_formulas.map do |compute_formula|
      parsed_compute_formula = JSON.parse(compute_formula.gsub('\"', '"').gsub('=>', ':'))
      evaluated_value = @@calculator.evaluate(
        replace_computed_formula_with(parsed_compute_formula["value"], data)
      )
      { title: parsed_compute_formula["title"], value: evaluated_value.to_f }
    end
  rescue => e
    raise e.message
  end

  def replace_computed_formula_with(value, data)
    found_formulas = value.scan(/row\(\d+\)col\(\d+\)/)
    found_formulas.each do |formula|
      value = value.gsub(formula, get_value_from_formula(formula, data))
    end
    return value
  rescue => e
    raise e.message
  end

  def get_value_from_formula(formula, data)
    row, col = formula.scan(/\d+/)
    value = data[row.to_i - 1][col.to_i]
    if !value
      raise "This is not a valid compute formula, value does not exist."
    end
    return value.gsub(/[^\w\s,\.]/, "")
  end

  def destroy
    financial_info = FinancialInfo.where(id: params[:id], user_id: current_user.id)
    financial_info.destroy_all
    render json: { message: "Financial Info has been deleted successfully" }
    return
  end

  private

  def financial_info_params
    params.permit(:data_source, :type_of_data, :flow_of_data, :user_id, :compute_formulas => [:title, :value])
   end
end
