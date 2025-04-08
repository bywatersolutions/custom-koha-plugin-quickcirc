# Custom-koha-plugin-quickcirc
Quick circulation plugin for special libraries - provides a single circ box that will either check out an item with a hold or return an issued item

This plugin has no tools or configuration options, it does add API routes for adding a 'QuickCirc' link at the top of the page

This link will launch a modal into which a barcode can be scanned.

If the item has an active hold, it will be issued to the borrower with the reserve.
If not, the item is checked in.
