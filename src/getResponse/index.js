
const { ENVIRONMENT } = process.env

const setResponse = (statusCode, body) => {
  return {
    statusCode,
    body: JSON.stringify(body) || undefined
  }
}

const handler = (event) => {
  console.log('Event: ', event)
  return setResponse(200, {})
}

module.exports = {
  handler
}
