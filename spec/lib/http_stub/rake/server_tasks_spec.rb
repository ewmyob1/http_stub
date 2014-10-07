describe HttpStub::Rake::ServerTasks do

  let(:default_args) { { port: 8001 } }
  let(:configurer)   { double(HttpStub::Configurer) }

  before(:each) { HttpStub::Rake::ServerTasks.new(default_args.merge(args)) }

  describe "the configure task" do

    context "when a configurer is provided" do

      let(:args) { { name: :configure_task_configurer_provided_test, configurer: configurer } }

      context "and the task is executed" do

        it "initializes the provided configurer" do
          configurer.should_receive(:initialize!)

          Rake::Task["configure_task_configurer_provided_test:configure"].execute
        end

      end

    end

    context "when a configurer is not provided" do

      let(:args) { { name: :configure_task_configurer_not_provided_test } }

      it "does not generate a task" do
        lambda { Rake::Task["configure_task_configurer_not_provided_test:configure"] }.should
          raise_error(/Don't know how to build task/)
      end

    end

  end

  describe "the reset task" do

    context "when a configurer is provided" do

      let(:args) { { name: :reset_task_configurer_provided_test, configurer: configurer } }

      context "and the task is executed" do

        it "resets the provided configurer" do
          configurer.should_receive(:reset!)

          Rake::Task["reset_task_configurer_provided_test:reset"].execute
        end

      end

    end

    context "when a configurer is not provided" do

      let(:args) { { name: :reset_task_configurer_not_provided_test } }

      it "does not generate a task" do
        lambda { Rake::Task["reset_task_configurer_not_provided_test:reset"] }.should
          raise_error(/Don't know how to build task/)
      end

    end

  end

end
