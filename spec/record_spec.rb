class User < RemoteModule::RemoteModel
  attr_accessor :id

  has_many :questions
end

class Answer < RemoteModule::RemoteModel
  attr_accessor :id

  belongs_to :question
end

class Question < RemoteModule::RemoteModel
  attr_accessor :id, :question

  belongs_to :user
  has_many :answers

  def user_id
    user && user.id
  end
end

describe "The active record-esque stuff" do
  it "creates object from hash" do
    hash = {id: 5, question: "Hello my name is clay"}
    q = Question.new(hash)
    hash.each {|key, value|
      q.send(key).should == value
    }

    # test other classes
    [User, Answer].each {|klass|
      hash = {id: 1337}
      obj = klass.new(hash)
      obj.id.should == hash[:id]
    }
  end

  it "creates nested objects" do
    hash = {id: 5, question: "question this", user: {id: 6}}
    q = Question.new(hash)
    q.user.class.should == User
    q.user.id.should == hash[:user][:id]
  end

  def check_question_and_answers(q, answers)
    q.answers.count.should == answers.count
    q.answers.each_with_index { |answer, index|
      answer.class.should == Answer
      answer.id.should == answers[index][:id]
      answer.question.should == q
    }
  end

  it "creates nested relationships" do
    answers = [{id: 3, id: 100}]
    hash = {id: 5, question: "my question", answers: answers}
    q = Question.new(hash)
    check_question_and_answers(q, answers)
  end

  it "creates inception relationships" do
    answers = [[], [{id: 3, id: 100}]]
    questions = [{id: 8, question: "question 8"}, {id: 10, question: "question 10", answers: answers[1]}]
    hash = {id: 1, questions: questions}
    u = User.new(hash)
    u.questions.count.should == questions.count
    u.questions.each_with_index {|q, index|
      q.class.should == Question
      q.user.should == u
      q.id.should == questions[index][:id]
      q.question.should == questions[index][:question]
      if q.answers.count > 0
        check_question_and_answers(q, answers[index])
      end
    }
  end
end