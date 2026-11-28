from __future__ import annotations

import asyncio
import unittest

import httpx

from app.main import app


class PlantHealthCorsTests(unittest.TestCase):
    def test_flutter_web_localhost_origin_can_post_health_images(self):
        async def make_request():
            async with httpx.AsyncClient(
                transport=httpx.ASGITransport(app=app),
                base_url="http://test",
            ) as client:
                return await client.options(
                    "/health-analysis",
                    headers={
                        "Origin": "http://localhost:42678",
                        "Access-Control-Request-Method": "POST",
                        "Access-Control-Request-Headers": "content-type",
                    },
                )

        response = asyncio.run(make_request())

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.headers["access-control-allow-origin"],
            "http://localhost:42678",
        )

    def test_non_localhost_origin_is_not_allowed_by_default(self):
        async def make_request():
            async with httpx.AsyncClient(
                transport=httpx.ASGITransport(app=app),
                base_url="http://test",
            ) as client:
                return await client.options(
                    "/health-analysis",
                    headers={
                        "Origin": "https://example.com",
                        "Access-Control-Request-Method": "POST",
                        "Access-Control-Request-Headers": "content-type",
                    },
                )

        response = asyncio.run(make_request())

        self.assertEqual(response.status_code, 400)
        self.assertNotIn("access-control-allow-origin", response.headers)


if __name__ == "__main__":
    unittest.main()
