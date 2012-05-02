# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120502032335) do

  create_table "api_accounts", :force => true do |t|
    t.integer  "user_id"
    t.string   "api_id"
    t.string   "api_id_hash"
    t.string   "api_source"
    t.string   "oauth_token"
    t.string   "oauth_secret"
    t.string   "real_name"
    t.string   "user_name"
    t.string   "image_url"
    t.string   "description"
    t.string   "language"
    t.string   "location"
    t.string   "status"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.boolean  "primary"
  end

  create_table "comments", :force => true do |t|
    t.text     "body"
    t.integer  "post_id"
    t.integer  "user_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "comments", ["created_at"], :name => "index_comments_on_created_at"
  add_index "comments", ["post_id"], :name => "index_comments_on_post_id"
  add_index "comments", ["user_id"], :name => "index_comments_on_user_id"

  create_table "mobile_sessions", :force => true do |t|
    t.integer  "user_id"
    t.string   "unique_identifier"
    t.string   "mobile_auth_token"
    t.string   "active"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  create_table "posts", :force => true do |t|
    t.string   "content"
    t.integer  "user_id"
    t.datetime "created_at",                                                                :null => false
    t.datetime "updated_at",                                                                :null => false
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.string   "hashtag_prefix"
    t.decimal  "price",                     :precision => 8, :scale => 2
    t.boolean  "open",                                                    :default => true
    t.integer  "api_account_id"
    t.string   "post_id"
    t.string   "last_result"
    t.string   "recipient_api_account_ids"
  end

  add_index "posts", ["updated_at"], :name => "index_posts_on_updated_at"
  add_index "posts", ["user_id", "created_at"], :name => "index_posts_on_user_id_and_created_at"

  create_table "user_logins", :force => true do |t|
    t.integer  "user_id"
    t.string   "user_agent"
    t.string   "ip_address"
    t.string   "url_referrer"
    t.string   "login_source"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.string   "session_json",    :limit => 500
    t.string   "paramaters_json", :limit => 500
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.string   "password_digest"
    t.string   "remember_token"
    t.boolean  "admin",           :default => false
    t.string   "twitter_atoken"
    t.string   "twitter_asecret"
  end

end
