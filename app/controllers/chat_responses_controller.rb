class ChatResponsesController < ApplicationController
  include ActionController::Live

  def show
    response.headers['Content-Type']  = 'text/event-stream'
    response.headers['Last-Modified'] = Time.now.httpdate
    sse                               = SSE.new(response.stream, event: "message")
    client                            = OpenAI::Client.new(access_token: ENV["OPENAI_ACCESS_TOKEN"])

    begin
      client.chat(
        parameters: {
          model:    "gpt-4o-mini",
          messages: [
                      { role: "user", content: params[:prompt] }],
          stream:   proc do |chunk|
            content = chunk.dig("choices", 0, "delta", "content")
            if content.nil?
              return
            end
            sse.write({
                        message: content,
                      })
          end
        }
      )
    ensure
      sse.close
    end
  end
end

# include ActionController::Live: Import the live module from the action controller namespace to stream the chat GPT responses using server-sent events.
# response.headers['Content-Type'] = 'text/event-stream': Set the content type header of the response to text/event-stream.
# response.headers['Last-Modified'] = Time.now.httpdate: Set the last modified header. This is a requirement in Rails action controller.
# sse = SSE.new(response.stream, event: "message"): Create a new SSE (server-sent events) stream with the event named "message".
# client = OpenAI::Client.new(access_token: ENV['OPENAI_ACCESS_TOKEN']): Instantiate the OpenAI client and pass it the access token.
# begin: Start the block to handle the chat process.
# client.chat(parameters: {...}): Call the chat method on the client object, specifying the model and parameters.
# model: "gpt-4o-mini": Specify the GPT model to use.
# messages: [{ role: "user", content: params[:prompt] }]: The prompt will come from the user and be passed as a query parameter in the API call.
# stream: proc do |chunk| ... end: Handle the incoming stream from the API.
# content = chunk.dig("choices", 0, "delta", "content"): Extract the content from the API response.
# return if content.nil?: Exit the procedure if the content is nil.
# sse.write({ message: content }): Write the content from the API response to the message event.
# ensure: Ensure that the SSE stream is closed after the process.
# sse.close: Stop sending events to the client and close the connection.





