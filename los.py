import subprocess
import sys

def install(package):
    subprocess.check_call([sys.executable, "-m", "pip", "install", package])

def install_requirements():
    packages = ['Faker', 'requests']
    for package in packages:
        install(package)

def main():
    from faker import Faker
    import requests
    import time

    # Türkçe yerel ayarı ile Faker nesnesini oluştur
    fake = Faker('tr_TR')

    # API URL'leri
    register_url = 'https://api.cizgi.studio/v1/auth/register'
    like_url = 'https://api.cizgi.studio/v1/likes/66a95355cc844f002f9ca9ae'
    rating_url = 'https://api.cizgi.studio/v1/ratings/66a95355cc844f002f9ca9ae'
    follow_url = 'https://api.cizgi.studio/v1/follows/66a950ad7251fe006946fc24/follow'
    episodes_url = 'https://api.cizgi.studio/v1/works/66a95355cc844f002f9ca9ae/episodes'
    reading_activities_url = 'https://api.cizgi.studio/v1/reading-activities'

    # Döngü sayısını başlat
    loop_count = 0

    while True:
        loop_count += 1

        # Rastgele veri oluştur
        data = {
            'email': fake.email(),
            'password': fake.password(length=12, special_chars=True, digits=True, upper_case=True, lower_case=True),
            'fullname': fake.name(),
            'username': fake.user_name()
        }

        # Kayıt POST isteği gönder
        response = requests.post(register_url, json=data)
        response_json = response.json()

        # Yanıtın anahtarlarını değişkenlere atama
        tokens = response_json.get('tokens', {})
        
        # Token bilgileri
        access_token = tokens.get('access', {}).get('token')
        refresh_token = tokens.get('refresh', {}).get('token')

        # Token'ları ekrana yazdırma
        print(f"Loop Count: {loop_count}")
        print(f"Access Token: {access_token}")
        print(f"Refresh Token: {refresh_token}")

        if access_token:
            # Başlıklar (Headers)
            headers = {
                'Host': 'api.cizgi.studio',
                'Sec-Ch-Ua': '"Not/A)Brand";v="8", "Chromium";v="126"',
                'Accept-Language': 'tr-TR',
                'Sec-Ch-Ua-Mobile': '?0',
                'Authorization': f'Bearer {access_token}',  # Token'ı başlıkta kullan
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.6478.127 Safari/537.36',
                'Content-Type': 'application/json',
                'Accept': 'application/json, text/plain, */*',
                'Sec-Ch-Ua-Platform': '"Windows"',
                'Origin': 'https://cizgi.studio',
                'Sec-Fetch-Site': 'same-site',
                'Sec-Fetch-Mode': 'cors',
                'Sec-Fetch-Dest': 'empty',
                'Referer': 'https://cizgi.studio/',
                'Priority': 'u=1, i',
            }

            # "Beğen" POST isteği gönder
            like_response = requests.post(like_url, headers=headers, verify=False)
            print(f"Status Code (Like): {like_response.status_code}")
            print(f"Response Body (Like): {like_response.text}")

            # Derecelendirme POST isteği gönder
            json_data = {'rating': 5}
            rating_response = requests.post(rating_url, headers=headers, json=json_data, verify=False)
            print(f"Status Code (Rating): {rating_response.status_code}")
            print(f"Response Body (Rating): {rating_response.text}")

            # Takip POST isteği gönder
            follow_response = requests.post(follow_url, headers=headers, verify=False)
            print(f"Status Code (Follow): {follow_response.status_code}")
            print(f"Response Body (Follow): {follow_response.text}")

            # Belirli bir URL'ye GET isteği gönder
            get_headers = {
                   'Host': 'api.cizgi.studio',
                'Sec-Ch-Ua': '"Not/A)Brand";v="8", "Chromium";v="126"',
                'Accept-Language': 'tr-TR',
                'Sec-Ch-Ua-Mobile': '?0',
                'Authorization': f'Bearer {access_token}',  # Token'ı başlıkta kullan
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.6478.127 Safari/537.36',
                'Content-Type': 'application/json',
                'Accept': 'application/json, text/plain, */*',
                'Sec-Ch-Ua-Platform': '"Windows"',
                'Origin': 'https://cizgi.studio',
                'Sec-Fetch-Site': 'same-site',
                'Sec-Fetch-Mode': 'cors',
                'Sec-Fetch-Dest': 'empty',
                'Referer': 'https://cizgi.studio/',
                'Priority': 'u=1, i',
            }

            params = {
                'work': '66a95355cc844f002f9ca9ae',
                'limit': '10',
                'isActive': 'true',
            }

            # GET isteği gönder
            get_response = requests.get(episodes_url, params=params, headers=get_headers, verify=False)
            print(f"Status Code (GET /episodes): {get_response.status_code}")
            print(f"Response Body (GET /episodes): {get_response.text}")

            # Reading Activities POST isteği gönder
            reading_activities_data = {
                'work': '66a95355cc844f002f9ca9ae',
            }
            reading_activities_response = requests.post(reading_activities_url, headers=headers, json=reading_activities_data, verify=False)
            print(f"Status Code (Reading Activities): {reading_activities_response.status_code}")
            print(f"Response Body (Reading Activities): {reading_activities_response.text}")

        else:
            print("Access Token alınamadı.")

        # Döngü arasında bir süre bekle (örneğin 1 saniye)
        time.sleep(1)

if __name__ == "__main__":
    install_requirements()
    main()
