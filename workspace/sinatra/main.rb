require 'sinatra'
require 'sinatra/reloader'
require 'active_record'
require 'pry'

ActiveRecord::Base.establish_connection(
    "adapter" => "sqlite3",
    "database" => "./bbs.db"
)

class Comment < ActiveRecord::Base
end


# 静的コンテンツ参照のためのパス設定
set :public, File.dirname(__FILE__) + '/public'


helpers do
    include Rack::Utils
    alias_method :h, :escape_html

    #トリップキーを返します
    def putTripkey(s)
        @pos =s.index("#")
        return nil if @pos == nil
        @tripkey = s.slice(@pos,s.size)
        
        return @tripkey
    end
    
    #トリップキー以外を返します
    def sliceComment(s)
        @pos =s.index("#")
        return s if @pos == nil
        @comment = s.slice(0,@pos)
        return  @comment
    end
    
    #トリップキーを変換します
    def trip10(tripkey)
        return "◆"  if tripkey == nil
        
        @salt = (tripkey + "H.").slice(1, tripkey.size)
        
        @salt = @salt.gsub(/[^\.-z]/, ".")
        @salt = @salt.tr(":;<=>?@[\\]^_`", "ABCDEFGabcdef");
     
        # 末尾から10文字取り出す
        @trip = "◆" + tripkey.crypt(@salt).slice(-10, 10);
        return @trip
    end


    # 画像をアップロード
    def imageLord
        if params[:file]
            
            save_path = "./public/images/#{params[:file][:filename]}"
            
	        File.open(save_path, 'wb') do |f|
	            f.write params[:file][:tempfile].read
	            @mes = ""
	        end
	        
	        save_path = "./images/#{params[:file][:filename]}"
            
	        return save_path 
	 
        else
	        @mes = "アップロードに失敗しました"
	        return nil
        end
    end    
	    
    
end

get '/' do
    @comments = Comment.order("id desc").all
    erb:index
end

post '/new' do
    
    @tripkey = putTripkey(params[:body])
    
    params[:body]= sliceComment(params[:body]) +  trip10(@tripkey) 
    
    
    Comment.create({:body => params[:body], :image => imageLord})
    
    redirect '/'
end

post '/delete' do
    Comment.find(params[:id]).destroy
end