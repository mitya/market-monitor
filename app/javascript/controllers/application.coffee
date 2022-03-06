import { Application } from "@hotwired/stimulus"

application = Application.start()
application.debug = false
window.Stimulus = application

export { application }
