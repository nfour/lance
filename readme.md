
## Lance
State: *Alpha*, Unstable-ish

Handles Stylus, Coffee and templating automatically while exposing routing, request handling etc. to a project.

### Todo

Most functionality is fleshed out, but...

Needs a re-structure, to create a neater function-object structure.  
Remove dependancy of the "requirer" module.  
Remove global object extension dependancy - in your own app they may be overwritten, you deal with it, but you shouldnt break anything within the lance module.
