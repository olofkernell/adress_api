# encoding: UTF-8
class HomeController < ApplicationController
    
  def index    
    @person = Person.new
    if current_person != nil
      @export = params
      
      @brforening = Brforening.find(PersonBrf.where(:person_id => current_person.id).first.brforening_id)
      @ids = Array.new
      PersonBrf.where(:brforening_id => @brforening.id).each do |i|
        @ids << i.person_id
      end
      @styrelse = Person.where(:id => @ids, :role_id => 1)
      
      if current_person.role_id == 1
        @contracts = Contract.where(:brforening_id => PersonBrf.where(:person_id => current_person.id).first.brforening_id).where("stoptime > ? and state > ?", (Date.today - 10.days).to_s, 0)
        @invoices = Invoice.where(:brforening_id => PersonBrf.where(:person_id => current_person.id).first.brforening_id, :invoice_type => 1).where("state > ?", 0)
        @documents = Document.where(:brforening_id => PersonBrf.where(:person_id => current_person.id).first.brforening_id)
      elsif current_person.role_id == 2
        @contracts = Contract.where(:brforening_id => PersonBrf.where(:person_id => current_person.id).first.brforening_id).where("stoptime > ? and state > ?", (Date.today - 10.days).to_s, 0)
        @invoices = Invoice.where(:brforening_id => PersonBrf.where(:person_id => current_person.id).first.brforening_id, :invoice_type => 1).where("state > ?", 0)
        @documents = Document.where(:brforening_id => PersonBrf.where(:person_id => current_person.id).first.brforening_id)
      elsif current_person.role_id == 3
        @contracts = Contract.where(:brforening_id => PersonBrf.where(:person_id => current_person.id).first.brforening_id).where("stoptime > ? and state > ?", (Date.today - 10.days).to_s, 0)
        @invoices = Invoice.where(:brforening_id => PersonBrf.where(:person_id => current_person.id).first.brforening_id, :invoice_type => 1).where("state > ?", 0)
        @documents = Document.where(:brforening_id => PersonBrf.where(:person_id => current_person.id).first.brforening_id)
      end
    end
    
    respond_to do |format|
        format.html # index.html.erb
        format.xml  { render :xml => @people }        
    end
  end
  
  def adress
#    match "/find_adress/:zip" => "home#adress", :as => :find_adress
#    match "/find_adress/:adress" => "home#adress", :as => :find_adress
#    match "/find_adress/:city" => "home#adress", :as => :find_adress
    
    if params[:adress].blank? == false
      @adress = params[:adress]      
      @c = Array.new
      Adress.find(:all, :conditions => ['street REGEXP ? ', '^'+@adress],:limit => 15).each do |adress|
        @c << {:street => adress.street, :street_nrs => adress.street_nrs, :zip => adress.zipcode.zip, :city => adress.zipcode.city}
      end      
    else
      @c = "no results"
    end
    
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @c }
    end
  end

  def zip  
    if params[:zip].blank? == false
      @zip = Zipcode.where(:zip => params[:zip]).first
      @c = Array.new
      Adress.where(:zipcode_id => @zip.id).each do |adress|
        @c << {:street => adress.street, :street_nrs => adress.street_nrs, :zip => @zip.zip, :city => @zip.city}
      end
    else
      @c = "no results"
    end
  
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @c }
    end
  end

  def city  
    if params[:zip].blank? == false
      @c = [1,2,3,4]
    else
      @c = "no results"
    end
  
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @c }
    end
  end


end
