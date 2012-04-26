# app/views/users/show.rabl

object @user

attributes :id, :name

code :gravatar do |user|
  gravatar_for user
end