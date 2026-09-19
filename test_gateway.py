import json
import traceback
from strands.tools.mcp.mcp_client import MCPClient

try:
    from mcp.client.streamable_http import streamablehttp_client
except ImportError:
    from mcp.client.streamable_http import streamable_http_client as streamablehttp_client

GATEWAY_URL = "https://customersupportgateway-hxua4b4ln7.gateway.bedrock-agentcore.us-east-1.amazonaws.com/mcp"

def _transport():
    return streamablehttp_client(GATEWAY_URL)

def main():
    print("Connecting to gateway:", GATEWAY_URL)
    client = MCPClient(_transport)
    with client:
        print("\n--- LISTING TOOLS ---")
        tools = client.list_tools_sync()
        for t in tools:
            name = getattr(t, "tool_name", None) or getattr(t, "name", str(t))
            print("  tool:", name)

        print("\n--- CALLING get_order (ORD-001) ---")
        get_order_name = None
        for t in tools:
            name = getattr(t, "tool_name", None) or getattr(t, "name", "")
            if "get_order" in name and "orders" not in name:
                get_order_name = name
                break

        if not get_order_name:
            print("  Hindi nahanap ang get_order tool.")
            return

        print("  Using tool name:", get_order_name)
        try:
            result = client.call_tool_sync(
                tool_use_id="test-1",
                name=get_order_name,
                arguments={"order_id": "ORD-001"},
            )
            print("\n--- RESULT ---")
            print(json.dumps(result, indent=2, default=str))
        except Exception:
            print("\n--- TOOL CALL ERROR ---")
            traceback.print_exc()

if __name__ == "__main__":
    try:
        main()
    except Exception:
        print("\n--- CONNECTION ERROR ---")
        traceback.print_exc()
