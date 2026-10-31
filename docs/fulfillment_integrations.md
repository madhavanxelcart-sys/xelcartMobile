# Fulfillment integration boundaries

## Order extraction

The default is a conservative local parser, labelled in the import sheet. It understands labelled recipient, phone, address, city, state, PIN, total, and `Item: name | variant | quantity` lines, plus simple order phrases. It never invents an address or marks incomplete data as complete. Sellers can correct fields and prices before saving. The conversation is retained on the session-local order.

To use a model-backed server:

    flutter run --dart-define=AI_ORDER_PARSER_URL=https://your-backend.example/orders/parse

The HTTPS endpoint receives POST JSON `{conversation, schema}` and returns a JSON object matching `ParsedOrderDto.jsonSchema`. The server must own model credentials, authenticate the seller, enforce authorization, and apply retention/rate limits. Inject `OrderExtractionBackend` or `parserHttpClientProvider` to integrate the app's authenticated client. No provider API keys belong in Flutter build flags. Non-2xx responses, oversized responses and malformed contracts fail closed. Validation always runs locally after extraction; model completeness flags are not trusted.

Phone normalization removes whitespace, one +91 prefix, then one leading zero. Canonical mobile numbers must match `^[6-9]\d{9}$`; PIN codes must match `^[1-9][0-9]{5}$`. Missing/invalid phone, PIN or street address always makes the DTO incomplete. Recipient name and at least one valid item are also required to save an order. The UI requires explicit prices and a total; it does not silently assign prices to unknown multi-item orders.

## BLE label printing

The default `SimulatedBlePrinterTransport` performs no OS scan or physical write. UI status and job completion explicitly say simulation. `BlePrinterTransport` is the native-GATT adapter boundary: implement real device discovery, characteristic selection, negotiated MTU limits, write acknowledgment/backpressure, cancellation of pending connects on disconnect, and device-specific capabilities. Physical printer pairing/permissions and firmware acceptance must be tested before using a native adapter.

Labels are rendered at 812 x 1218 dots (4 x 6 inches at 203 DPI), with Code 128 AWB bars, recipient, phone and address. Address overflow fails instead of truncating delivery information. Rows are padded to 102 bytes; the four padding bits are white. The generator emits MSB-first monochrome dark bits. TSPL BITMAP uses inverted polarity (zero prints a dot); ESC/POS GS v 0 uses one for a dot. ESC/POS raster support varies by model and is opt-in through printer capabilities. The job is chunked to `maxWriteBytes`, cancels on disconnect and does not automatically retry partial failures. Non-simulated completion means bytes were sent, not that a physical label was confirmed. A real shipment AWB is required; imported orders do not fabricate tracking numbers.

Protocol references:
- TSC TSPL/TSPL2 programming manual: https://fs.tscprinters.com/system/files/31-0000001-00_tspl_tspl2_programming_3_0.pdf
- Epson raster reference: https://download4.epson.biz/sec_pubs/pos/reference_en/escpos/gs_lv_0.html

## Settings and session lifetime

Channel, UPI provider and logistics configurations store public HTTPS backend URLs and optional account labels for this session only. They are shown as configured but not verified; no OAuth, payment link or shipment API call is fabricated. Keep provider secrets on the server. Implement authenticated backend status endpoints before reporting any integration as connected.

Sign out disconnects/cancels the printer, removes the last label and resets orders, inventory, product drafts, onboarding data and integration settings before returning to Login. The existing repositories remain mock/session-local; there is no remote order persistence in this implementation.
