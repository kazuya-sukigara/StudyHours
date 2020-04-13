class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable,omniauth_providers: [:twitter,:google]

  # ノートのアソシエーション
  has_many :notes ,dependent: :destroy
  has_many :note_favorites ,dependent: :destroy
  has_many :note_comments ,dependent: :destroy

  #　学習記録のアソシエーション
  has_many :study_logs ,dependent: :destroy
  has_many :study_log_favorites ,dependent: :destroy
  has_many :study_log_comments ,dependent: :destroy

  # フォロー・フォロワーのアソシエーション
  has_many :relationships
  has_many :followings,through: :relationships,source: :follow
  has_many :reverse_of_relationships,class_name: 'Relationship',foreign_key: 'follow_id'
  has_many :followers,through: :reverse_of_relationships, source: :user
  has_many :entries
  has_many :rooms, through: :entries
  has_many :chats

  # refileを使うための設定
  attachment :profile_image

  # ユーザ名が空白じゃない
  validates :name, presence: true
  # 目標時間(時間)が0~23時間
  validates :goal_hour, length: {in: 0..23},presence: true
  # 目標時間(分)が0~59分
  validates :goal_minute, length: {in: 0..59},presence: true
  # 自己紹介文が200文字以内
  validates :introduction,length: {maximum: 200}

  # 対象ユーザがフォロー中か確認するメソッド
  def following?(user)
    self.followings.include?(user)
  end

  # 対象ユーザをフォローするメソッド
  def follow(user)
    if self.following?(user) == false
      self.relationships.create(follow_id: user.id)
    end
  end

  # 対象ユーザのフォローを解除するメソッド
  def unfollow(user)
    self.relationships.find_by(follow_id: user.id).destroy
  end

  # １週間の学習時間を表示するメソッド
  def weekly_study_logs
    hour = 0
    min = 0
    # 月曜日~日曜日で集計を行う(rubyの標準)
    self.study_logs.where(working_date: (Date.today.beginning_of_week)..(Date.today.end_of_week)).each do |weekly_study_log|
      weekly_study_log.study_log_details.each do |detail|
        hour += detail.hour
        min += detail.min
      end
    end
    calchour = min / 60
    hour += calchour
    min = min % 60
    return [hour,min]
  end

  # 今週の目標に対する進捗率を表示するメソッド(分単位で計算・return値は%現在何%か)
  def weekly_progress
    study_hours = (self.weekly_study_logs[0] * 60 + self.weekly_study_logs[1]).to_f
    goal_hours = (self.goal_hour * 60 + self.goal_minute).to_f
    if goal_hours == 0
      return 100
    else
      return ((study_hours / goal_hours).floor(1) * 100).to_i
    end
  end


protected
  def self.from_omniauth(auth)
    # twitterの場合メールアドレスが持ってこれないため、ダミーデータが登録されている
    if auth.provider == :twitter
      user = User.find_by(email: User.dummy_email(auth))
    else
      user = User.find_by(email: auth.info.email)
    end

    unless user
      case auth.provider
      when :twitter then 
        user = User.create(provider: auth.provider,uid: auth.uid,email: User.dummy_email(auth),name: auth.info.name,password: Devise.friendly_token[0,20])
      when :google then
        user = User.create(provider: auth.provider,uid: auth.uid,email: auth.info.email,name: auth.info.name,password: Devise.friendly_token[0,20])
      end
    end
    user
  end

# Twitterのアカウントはemailがnilとなってしまうため、ダミーを用意する
  def self.dummy_email(auth)
    return "#{auth.uid}-#{auth.provider}@dummy.co.jp"
  end
end
