# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 10) do

  create_table "comments", :force => true do |t|
    t.integer  "revision_id", :null => false
    t.integer  "user_id",     :null => false
    t.text     "comment"
    t.datetime "created_at"
  end

  create_table "pages", :force => true do |t|
    t.string "title", :null => false
  end

  add_index "pages", ["title"], :name => "pages_title_index", :unique => true

  create_table "revisions", :force => true do |t|
    t.integer  "page_id",    :null => false
    t.text     "content"
    t.datetime "created_at"
    t.integer  "user_id",    :null => false
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id"
    t.text     "data"
    t.datetime "updated_at"
  end

  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"
  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"

  create_table "taggings", :force => true do |t|
    t.integer "taggable_id"
    t.integer "tag_id"
    t.string  "taggable_type"
  end

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  create_table "users", :force => true do |t|
    t.string "name"
    t.string "key"
  end

end
