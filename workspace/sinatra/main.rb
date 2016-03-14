require 'sinatra'
require 'sinatra/reloader'
require 'active_record'
require 'pry'

ActiveRecord::Base.establish_connection(
  "adapter" => "sqlite3",
  "database" => "./bbs.db"
)


Comment = Class.new(ActiveRecord::Base)

helpers do
  include Rack::Utils
  alias_method :h, :escape_html
  
  #トリップキーを返します
  def put_tripkey(s)
      
    @pos =s.index("#")
    return nil if @pos == nil
    
    @tripkey = s.slice(@pos,s.size)
  end
    
  #トリップキー以外を返します
  def slice_comment(s)
    @pos =s.index("#")
    return s if @pos == nil
    
    @comment = s.slice(0,@pos)
  end
    
  #トリップキーを変換します
  def trip10(tripkey)
    return "◆"  if tripkey == nil
    
    @salt = (tripkey + "H.").slice(1, tripkey.size)
    @salt = @salt.gsub(/[^\.-z]/, ".")
    @salt = @salt.tr(":;<=>?@[\\]^_`", "ABCDEFGabcdef")
     
    # 末尾から10文字取り出す
    @trip = "◆" + tripkey.crypt(@salt).slice(-10, 10);
  end


  # 画像をアップロード
  def image_load
    if params[:file]
      
      @save_path = "./public/images/#{params[:file][:filename]}"
      
      File.open(@save_path, 'wb') do |f|
	    f.write params[:file][:tempfile].read
      end
	  
	  #カレントディレクトリが[public]になっているのでpathを合わせる
	  @load_path =  @save_path.gsub("public/", "./")
    end
  end    
	    
end

get '/' do
  @comments = Comment.order("id desc").all
  erb:index
end

post '/new' do
  @tripkey = put_tripkey(params[:body])
  params[:body]= slice_comment(params[:body]) +  trip10(@tripkey)
  
  Comment.create({ body: params[:body], image: image_load })

  redirect '/'
end

post '/delete' do
  Comment.find(params[:id]).destroy
end
