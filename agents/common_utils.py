from geopy.geocoders import Nominatim
from database.vector_db import VectorDB

# Initialize VectorDB once
vector_db = VectorDB()

def get_user_location_context(location_data):
    """
    Reverse geocodes the lat/lon to get City and State.
    Returns:
        tuple: (city, state, location_string)
    """
    city = "Unknown"
    state_name = "Unknown"
    loc_str = "Location not provided"

    if location_data:
        try:
            geolocator = Nominatim(user_agent="nyaysahayak_common_utils")
            # Limit precision to speed up
            location = geolocator.reverse(f"{location_data['lat']}, {location_data['lon']}", language="en")
            address = location.raw.get('address', {})
            city = address.get('city', address.get('town', address.get('village', 'Unknown')))
            state_name = address.get('state', 'Unknown')
            loc_str = f"{city}, {state_name}"
            print(f"📍 Detected Location: {loc_str}")
        except Exception as e:
            print(f"❌ Geocoding error: {e}")
            
    return city, state_name, loc_str

def get_local_scam_summary(city):
    """
    Searches VectorDB for scams in the given city and returns a summary string.
    """
    if city == "Unknown":
        return "No location data available to check for local scams."

    local_scams = vector_db.search(query="recent scams", namespace="scams", filter={"city": city})
    
    if local_scams:
        print(f"   Context Retrieved: {len(local_scams)} local scam reports.")
        return "\n".join([f"- {s}" for s in local_scams])
    else:
        print(f"   Context Retrieved: 0 local scam reports.")
        return "No specific recent scams reported in this area."
