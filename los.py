from instagrapi import Client
import os
from bs4 import BeautifulSoup
import requests

def rastgele_siir():
    # Fetch a random poem from the website
    try:
        r = requests.get("https://www.antoloji.com/siir/rastgele/")
        r.raise_for_status()  # Ensure we notice bad responses
        soup = BeautifulSoup(r.content, "html.parser")
        siir_baslik = soup.find("div", attrs={"class": "pd-title"})
        siir_icerik = soup.find("div", attrs={"class": "pd-text"})
        
        if not siir_baslik or not siir_icerik:
            return "Şiir bulunamadı."
        
        baslik = siir_baslik.find("h3").get_text() if siir_baslik.find("h3") else "Başlık yok"
        siir = " ".join(p.get_text() for p in siir_icerik.find_all("p"))
        
        # Format the caption with title and poem
        caption = f"{baslik}\n\n{siir}"
        return caption
    except Exception as e:
        return f"Error fetching poem: {e}"

def post_on_instagram():
    username = "canvastalesai"
    password = "ASDdsa03."
    photo_dir = "/content/io/output"  # Directory containing photos

    # Initialize the Instagram client
    client = Client()

    try:
        # Login to Instagram
        client.login(username, password)
        
        # List all files in the photo directory
        files = [f for f in os.listdir(photo_dir) if os.path.isfile(os.path.join(photo_dir, f))]
        
        # Post each photo, limit to 5 photos
        max_posts = 5
        for i, file in enumerate(files):
            if i >= max_posts:
                break
            photo_path = os.path.join(photo_dir, file)
            # Get a random poem for the caption
            hashtags = '#şiir #aşk #şiirsokakta #edebiyat #istanbul #kitap #şiirheryerde #söz #siirsokakta #sevgi #şair #güzelsözler #izmir #ankara #sözler #iyigeceler #instagram #siir #cemalsüreya #love #yazar #türkiye #tbt #müzik #huzur #günaydın #mutluluk #instagood #turkey #ask'
            
            # Generate caption with hashtags
            caption = f"{rastgele_siir()}\n\n{hashtags}"
            
            # Upload the photo
            media = client.photo_upload(photo_path, caption=caption)
            print(f"Photo uploaded successfully! Media ID: {media.id}")

    except Exception as e:
        print(f"Error posting to Instagram: {e}")

if __name__ == "__main__":
    post_on_instagram()
