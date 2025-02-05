# prompt_manager/test/prompt_manager/prompt_test.rb

require_relative '../test_helper'

class PromptTest < Minitest::Test
  # Mock storage adapter that will act as a fake database in tests
  class MockStorageAdapter
    @@db = {} # generic database - a collection of prompts

    attr_accessor :id, :text, :parameters 
    
    def db = @@db

    def initialize
      @id         = nil # String name of the prompt
      @text       = nil # String raw text with parameters
      @parameters = nil # Hash for current prompt
    end

    def get(id:)
      raise("Prompt ID not found") unless @@db.has_key? id

      record = @@db[id]

      @id         = id
      @text       = record[:text]
      @parameters = record[:parameters]

      record
    end

    def save(id: @id, text: @text, parameters: @parameters)
      @@db[id] = { text: text, parameters: parameters }
      true
    end

    def delete(id: @id)
      raise("What") unless @@db.has_key?(id)
      db.delete(id)
    end

    def search(query)
      @@db.select { |k, v| v[:text].include?(query) }
    end
  end

  ##########################################
  def setup
    @storage_adapter = MockStorageAdapter.new

    @storage_adapter.save(
      id:         'test_prompt', 
      text:       "Hello, [NAME]!", 
      parameters: {'[NAME]' => 'World'}
    )

    PromptManager::Prompt.storage_adapter = @storage_adapter
  end


  ##########################################
  def test_prompt_initialization_raises_argument_error_when_id_blank
    assert_raises ArgumentError do
      PromptManager::Prompt.new(id: '')
    end
  end


  def test_prompt_initialization_raises_argument_error_when_no_storage_adapter_set
    PromptManager::Prompt.storage_adapter = nil
    assert_raises ArgumentError do
      PromptManager::Prompt.new(id: 'test_prompt')
    end
  ensure
    PromptManager::Prompt.storage_adapter = @storage_adapter
  end


  def test_prompt_interpolates_parameters_correctly
    prompt = PromptManager::Prompt.new(id: 'test_prompt')
    assert_equal "Hello, World!", prompt.to_s
  end


  def test_prompt_saves_to_storage
    new_prompt_id         = 'new_prompt'
    new_prompt_text       = "How are you, [NAME]?"
    new_prompt_parameters = { 'name' => 'Rubyist' }

    PromptManager::Prompt.create(
      id:         new_prompt_id,
      text:       new_prompt_text,
      parameters: new_prompt_parameters
    )

    prompt_from_storage = @storage_adapter.get(id: 'new_prompt')

    assert_equal new_prompt_text,       prompt_from_storage[:text]
    assert_equal new_prompt_parameters, prompt_from_storage[:parameters]
  end


  def test_prompt_deletes_from_storage
    prompt = PromptManager::Prompt.create(id: 'test_prompt')
    
    assert PromptManager::Prompt.get(id: 'test_prompt') # Verify it exists

    prompt.delete

    assert_raises do
      PromptManager::Prompt.get(id: 'test_prompt') # Should raise "Prompt ID not found"
    end
  end


  def test_prompt_searches_storage
    search_results  = PromptManager::Prompt.search('Hello')

    refute_empty search_results
    assert search_results.keys.include?('test_prompt')
  end
end

__END__
