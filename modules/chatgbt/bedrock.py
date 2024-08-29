import boto3, json, traceback
import streamlit as st

def send_prompt_to_bedrock(prompt):
  bedrock = boto3.client(service_name='bedrock-runtime', region_name='us-west-2')
  request_body = {
    "anthropic_version": "bedrock-2023-05-31",
    "max_tokens": 2048,
    "messages": [
      {
          "role": "user",
          "content": prompt
      }
    ]
  }

  try:
    # Invoke the Anthropic Claude Sonnet model
    response = bedrock.invoke_model_with_response_stream(
      modelId='anthropic.claude-v2',
      #modelId="anthropic.claude-3-sonnet-20240229-v1:0",
      body=json.dumps(request_body)
    )

    # Get the event stream and process it
    event_stream = response.get('body', {})
    for event in event_stream:
      chunk = event.get('chunk')
      if chunk:
        message = json.loads(chunk.get("bytes").decode())
        if message['type'] == "content_block_delta":
          yield message['delta']['text'] or ""
        elif message['type'] == "message_stop":
          return "\n"
  except Exception as e:
    print(traceback.format_exc())
    return f"Error: {str(e)}"

# Set the title of the app
st.set_page_config(page_title="🪨 Amazon Bedrock demo: invoke_model_with_response_stream")

# Add a title
st.title("Demo: invoke_model_with_response_stream")

st.markdown(
    """
    This is a demo of Amazon Bedrock's invoke_model_with_response_stream API. To learn more about this API, check out the API docs [here](https://docs.aws.amazon.com/bedrock/latest/APIReference/API_runtime_InvokeModelWithResponseStream.html).
    """
)

# Add a text area for the prompt
prompt = st.text_area("Prompt")

# Add a button
if prompt:
  result = send_prompt_to_bedrock(prompt)
  st.write_stream(result)